# frozen_string_literal: true

require 'test_helper'
require 'ostruct'

class VerifierTest < CommonTest
  def setup
    @private_key = private_key
    @public_key = @private_key.public_key
    @verifier = HealthCards::Verifier.new(keys: @public_key)
    @jws = issuer.issue_jws(bundle_payload)
    @extra_key_path = "#{key_path}-verifier-test"
    @extra_key = HealthCards::PrivateKey.load_from_or_create_from_file(@extra_key_path)
  end

  def teardown
    super
    FileUtils.rm_rf(@extra_key_path) if File.exist?(@extra_key_path)
  end

  ## Constructors

  def test_create_a_new_verifier_with_a_public_key
    HealthCards::Verifier.new(keys: @public_key)
  end

  def test_create_a_new_verifier_with_a_private_key
    HealthCards::Verifier.new(keys: @private_key)
  end

  def test_create_a_new_verifier_with_a_KeySet
    key_set = HealthCards::KeySet.new(@public_key)
    HealthCards::Verifier.new(keys: key_set)
  end

  ## Key Export
  def test_verifier_exports_public_keys_as_JWK
    verifier = HealthCards::Verifier.new(keys: @private_key)
    key_set = verifier.keys
    assert key_set.is_a? HealthCards::KeySet
  end

  ## Adding and Removing Keys
  def test_verifier_allows_public_keys_to_be_added
    verifier = HealthCards::Verifier.new
    assert_empty verifier.keys
    verifier.add_keys @public_key
    assert_not_empty verifier.keys
    assert_includes verifier.keys, @public_key
  end

  def test_verifier_allows_public_keys_to_be_removed
    verifier = HealthCards::Verifier.new(keys: @public_key)
    assert_not_empty verifier.keys
    assert_includes verifier.keys, @public_key
    verifier.remove_keys @public_key
    assert_empty verifier.keys
  end

  def test_verifier_allows_private_keys_to_be_added
    verifier = HealthCards::Verifier.new
    assert_empty verifier.keys
    verifier.add_keys @private_key
    assert_not_empty verifier.keys
    assert_includes verifier.keys, @private_key
  end

  def test_verifier_allows_private_keys_to_be_removed
    verifier = HealthCards::Verifier.new(keys: @private_key)
    assert_not_empty verifier.keys
    assert_includes verifier.keys, @private_key
    verifier.remove_keys @private_key
    assert_empty verifier.keys
  end

  ## Verification

  def test_verifier_can_verify_JWS_object
    assert @verifier.verify(@jws)
  end

  def test_verifier_can_verify_JWS_string
    assert @verifier.verify(@jws.to_s)
  end

  def test_verifier_can_verify_a_healthcard
    card = HealthCards::HealthCard.new(@jws)
    assert @verifier.verify(card)
  end

  def test_verifier_doesnt_verify_none_JWSable_object
    assert_raises ArgumentError do
      @verifier.verify(OpenStruct.new(foo: 'bar'))
    end
  end

  def test_verifier_throws_exception_when_attempting_to_verify_health_card_without_an_accessible_public_key
    verifier = HealthCards::Verifier.new
    Net::HTTP.stub :get, ->(url) { HealthCards::KeySet.new(@extra_key).to_jwk } do
      assert_raises HealthCards::MissingPublicKeyError do
        verifier.verify @jws
      end

      assert_raises HealthCards::MissingPublicKeyError do
        verifier.verify @jws
      end
    end
  end

  def test_verifier_can_verify_JWS_when_key_is_resolvable
    verifier = HealthCards::Verifier.new
    Net::HTTP.stub :get, ->(url) { @verifier.keys.to_jwk } do
      assert verifier.verify(@jws)
    end
  end

  ### Verification Class Methods
  def test_verifier_class_throws_exception_when_attempting_to_verify_health_card_without_an_accessible_public_key
    verifier = HealthCards::Verifier
    Net::HTTP.stub :get, ->(url) { HealthCards::KeySet.new(@extra_key).to_jwk } do
      assert_raises HealthCards::MissingPublicKeyError do
        verifier.verify @jws
      end
    end
  end

  def test_verifier_class_can_verify_health_cards_when_key_is_resolvable
    verifier = HealthCards::Verifier
    Net::HTTP.stub :get, ->(url) { @verifier.keys.to_jwk } do
      assert verifier.verify(@jws)
    end
  end

  ## Key Resolution

  def test_verifier_key_resolution_is_active_by_default
    assert HealthCards::Verifier.new.resolve_keys?
  end

  def test_verifier_key_resolution_can_be_disabled
    verifier = HealthCards::Verifier.new
    assert verifier.resolve_keys?
    verifier.resolve_keys = false
    assert(!verifier.resolve_keys?)
    verifier.resolve_keys = true
  end

  def test_verifier_will_not_verify_health_cards_when_key_is_not_resolveable
    verifier = HealthCards::Verifier.new

    Net::HTTP.stub :get, ->(url) { @verifier.keys.to_jwk } do
      verifier.resolve_keys = false
      assert_raises HealthCards::MissingPublicKeyError do
        verifier.verify(@jws)
      end
      verifier.resolve_keys = true
      assert verifier.verify(@jws)
    end
  end

  def test_verifier_will_raise_an_error_if_no_valid_key_is_found
    verifier = HealthCards::Verifier
    Net::HTTP.stub :get, ->(url) { raise StandardError, "Not found" } do
      assert_raises HealthCards::UnresolvableKeySetError do
        verifier.verify(@jws)
      end
    end
  end

  def test_verifier_will_raise_a_payload_error_if_key_resolution_times_out
    verifier = HealthCards::Verifier.new
    Net::HTTP.stub :get, ->(url) { raise StandardError, "Timed out" } do
      assert_raises HealthCards::UnresolvableKeySetError do
        verifier.verify(@jws)
      end
    end
  end

  def test_verifier_class_will_verify_health_cards_when_key_is_resolvable
    verifier = HealthCards::Verifier.new
    jwk = HealthCards::KeySet.from_jwks(@verifier.keys.to_jwk)
    verifier.stub :resolve_key, ->(_) { jwk } do
      assert verifier.verify(@jws)
    end
  end

  ## Test Against Spec Examples
  def test_against_example_data
    jws = 'eyJ6aXAiOiJERUYiLCJhbGciOiJFUzI1NiIsImtpZCI6IjNLZmRnLVh3UC03Z1h5eXd0VWZVQUR3QnVtRE9QS01ReC1pRUxMMTFXOXMifQ.'\
          '3ZJLb9swEIT_SrC9ypKo1HWsW5wCfRyKAk17KXygqbXFgA-BpIS4gf57d2kHaIE4p56q24rDjzNDPoGOEVroUxpiW1XRypB6lCb1pZKhixU'\
          '-SjsYjBUJRwxQgNvtoRXvmvp6vbxeinJ1c1PApKB9gnQcENqfl3FvTsOCB0Jd1mlrR6d_yaS9e1Wo_KQ7sYZtASpghy5pab6NuwdUiS3tex'\
          '1-YIjMaeFtWZeCePx3M7rOIGsCRj8GhffZPpwXinMcUN4Yop2c0AHhSBmJPBrzPRgSPO9vaxI8Dy-Av1Ic2s8dSosniLTaEA9uHWlCzGcc9'\
          'ISOe_zse543JWxnCrjTFP69TMwS66VY1GLR1DDPxYtuxOtuPv1dcUwyjTHH5QtPyBc0SaW0wzvfZYLynXaHbDweY0J7fjp0M71ZlT4cKm62'\
          'irqr1PRIAJV3QlOvYN7OBQznCrKdPQZ07O3PBknklRpDXuKw99qeEE0OXHMsqmrvg6X3yF6kSj4wstNxMDLXubm7-oAOgzRXH30cdJKGiqI'\
          'SjU9fRrvjrVDnT1xssPkvG2zW_7rBFS_M9P0G.jLfaCb4OaneXDv1p9U29fcWGRkgWnMYizLrRAN_uOsdNRlY5m5Jcot-KHxV1fKjAyCj2D'\
          'dmdrze8VbqfY8hoHg'

    jwk = {
      kty: 'EC',
      kid: '3Kfdg-XwP-7gXyywtUfUADwBumDOPKMQx-iELL11W9s',
      use: 'sig',
      alg: 'ES256',
      crv: 'P-256',
      x: '11XvRWy1I2S0EyJlyf_bWfw_TQ5CJJNLw78bHXNxcgw',
      y: 'eZXwxvO1hvCY0KucrPfKo7yAyMT6Ajc3N7OkAB6VYy8'
    }
    assert HealthCards::Verifier.new(keys: HealthCards::Key.from_jwk(jwk)).verify(jws)
  end
end
