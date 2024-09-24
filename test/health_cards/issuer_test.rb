# frozen_string_literal: true

require 'test_helper'

class IssuerTest < CommonTest
  def setup
    @bundle = bundle_payload
    @private_key = private_key
    @issuer = HealthCards::Issuer.new(key: @private_key)
  end

  ## Constructors

  def test_create_a_new_issuer
    HealthCards::Issuer.new(key: @private_key)
  end

  def test_issuer_raises_exceptioN_when_initializing_with_public_key
    assert_raises HealthCards::InvalidKeyError do
      HealthCards::Issuer.new(key: @private_key.public_key)
    end
  end

  ## Creating Health Cards

  def test_generate_a_health_card_from_an_issuer
    health_card = @issuer.issue_health_card(@bundle)
    assert health_card.is_a?(HealthCards::HealthCard)
    assert_equal @bundle.entry[0].resource, health_card.bundle.entry[0].resource
  end

  ## Key Export

  def test_issuer_exports_public_key_as_JWK
    key = JSON.parse(@issuer.to_jwk)
    # TODO: Add more checks once we can ingest external public keys
    assert @issuer.key.public_key.kid, key['kid']
  end

  ## Adding and Changing Keys

  def test_issuer_allows_private_keys_to_be_changed
    key2 = HealthCards::PrivateKey.generate_key
    @issuer.key = key2
    assert_not_nil @issuer.key
    assert_not_equal @issuer.key, @private_key
  end

  def test_issuer_does_not_allow_public_key_to_be_added
    assert_raises HealthCards::InvalidKeyError do
      @issuer.key = @private_key.public_key
    end
  end

  ## Integration Tests

  def test_issuer_signed_jws_are_signed_with_set_private_key
    jws = @issuer.issue_jws(@bundle)
    assert jws.verify
  end
end
