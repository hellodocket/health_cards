# frozen_string_literal: true

require 'test_helper'
require 'fileutils'

class KeyTest < CommonTest
  def setup
    @key_path = key_path
    @key = HealthCards::PrivateKey.load_from_or_create_from_file(@key_path)
    @test_jwk = {
      kty: 'EC',
      kid: '3Kfdg-XwP-7gXyywtUfUADwBumDOPKMQx-iELL11W9s',
      use: 'sig',
      alg: 'ES256',
      crv: 'P-256',
      x: '11XvRWy1I2S0EyJlyf_bWfw_TQ5CJJNLw78bHXNxcgw',
      y: 'eZXwxvO1hvCY0KucrPfKo7yAyMT6Ajc3N7OkAB6VYy8'
    }
  end

  def teardown
    cleanup_keys
  end

  def test_it_creates_keys
    assert_path_exists(@key_path)
  end

  def test_kid_calculation_is_correct
    jwk = HealthCards::Key.from_jwk(@test_jwk)
    assert_equal jwk.kid, @test_jwk[:kid]
  end

  def test_exports_to_jwk
    jwk = @key.public_key.to_jwk

    assert_not_nil jwk[:x]
    assert_not_nil jwk[:y]
    assert_nil jwk[:d]

    assert_equal 'sig', jwk[:use]
    assert_equal 'ES256', jwk[:alg]
  end

  def test_create_key_from_jwk_containing_the_private_key
    jwk = @key.to_jwk
    jwk_key = HealthCards::Key.from_jwk(jwk)

    assert jwk_key.is_a? HealthCards::PrivateKey

    assert_not_nil jwk[:x]
    assert_not_nil jwk[:y]
    assert_not_nil jwk[:d]

    assert_equal @key.kid, jwk_key.kid

    new_jwk = jwk_key.to_jwk
    assert_equal jwk[:x], new_jwk[:x]
    assert_equal jwk[:y], new_jwk[:y]
    assert_equal jwk[:d], new_jwk[:d]
  end

  def test_create_key_from_jwk_containing_the_public_key
    jwk = @key.public_key.to_jwk
    jwk_key = HealthCards::Key.from_jwk(jwk)

    assert jwk_key.is_a? HealthCards::PublicKey

    assert_not_nil jwk[:x]
    assert_not_nil jwk[:y]
    assert_nil jwk[:d]

    assert_equal @key.kid, jwk_key.kid

    new_jwk = jwk_key.to_jwk
    assert_equal jwk[:x], new_jwk[:x]
    assert_equal jwk[:y], new_jwk[:y]
  end

  def test_public_coordinates_dont_include_d
    pk = @key.public_key
    assert_nil pk.public_coordinates[:d]
    assert_equal @key.public_coordinates, pk.coordinates
  end

  def test_use_existing_keys_if_they_exist
    original_jwks = @key.public_key.to_json

    new_jwks = HealthCards::PrivateKey.load_from_or_create_from_file(@key_path).public_key.to_json

    assert_equal original_jwks, new_jwks
  end

  def test_verify_payload
    payload = 'foo'
    sigg = @key.sign('foo')
    assert @key.public_key.verify(payload, sigg)
  end
end
