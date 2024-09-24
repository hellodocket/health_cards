# frozen_string_literal: true

require 'test_helper'

class KeySetTest < CommonTest
  def setup
    @keys = [HealthCards::PrivateKey.generate_key, HealthCards::PrivateKey.generate_key]
  end

  ## Constructors

  def test_KeySet_can_be_initialized_without_keys
    HealthCards::KeySet.new
  end

  def test_KeySet_can_be_initialized_with_a_single_private_key
    HealthCards::KeySet.new(@keys[0])
  end

  def test_KeySet_can_be_initialized_with_a_single_public_key
    HealthCards::KeySet.new(@keys[0].public_key)
  end

  def test_KeySet_can_be_initialized_with_an_array_of_private_keys
    key_set = HealthCards::KeySet.new(@keys)
    assert_includes key_set, @keys[0]
    assert_includes key_set, @keys[1]
  end

  def test_KeySet_can_be_intiailized_with_an_array_of_public_keys
    key_set = HealthCards::KeySet.new(@keys.map(&:public_key))
    assert_includes key_set, @keys[0].public_key
    assert_includes key_set, @keys[1].public_key
  end

  def test_KeySet_can_be_created_from_a_JWKS
    jwks = HealthCards::KeySet.new(@keys).to_jwk
    key_set = HealthCards::KeySet.from_jwks(jwks)
    assert_includes key_set, @keys[0]
    assert_includes key_set, @keys[1]
  end

  ## Adding and Removing Keys

  def test_single_private_key_can_be_added_to_an_existing_KeySet
    key_set = HealthCards::KeySet.new
    assert_not_includes key_set, @keys[0]
    key_set.add_keys @keys[0]
    assert_includes key_set, @keys[0]
  end

  def test_single_private_key_can_be_removed_from_an_existing_KeySet
    key_set = HealthCards::KeySet.new(@keys[0])
    assert_includes key_set, @keys[0]
    key_set.remove_keys @keys[0]
    assert_not_includes key_set, @keys[0]
  end

  def test_array_of_private_keys_can_be_added_to_an_existing_keyset
    key_set = HealthCards::KeySet.new
    assert_not_includes key_set, @keys[0]
    assert_not_includes key_set, @keys[1]
    key_set.add_keys @keys
    assert_includes key_set, @keys[0]
    assert_includes key_set, @keys[1]
  end

  def test_array_of_private_keys_can_be_removed_from_an_existing_KeySet
    key_set = HealthCards::KeySet.new(@keys)
    assert_includes key_set, @keys[0]
    assert_includes key_set, @keys[1]
    key_set.remove_keys @keys
    assert_not_includes key_set, @keys[0]
    assert_not_includes key_set, @keys[1]
  end

  def test_KeySet_can_be_added_to_an_existing_KeySet
    diff_keys = [private_key, private_key]
    key_set2 = HealthCards::KeySet.new(diff_keys)

    key_set = HealthCards::KeySet.new(@keys)
    assert_not_includes key_set, diff_keys[0]
    assert_not_includes key_set, diff_keys[1]
    key_set.add_keys(key_set2)
    assert_includes key_set, diff_keys[0]
    assert_includes key_set, diff_keys[1]
  end

  def test_KeySet_can_be_removed_from_an_existing_KeySet
    key_set2 = HealthCards::KeySet.new(@keys)

    key_set = HealthCards::KeySet.new(@keys)
    assert_includes key_set, @keys[0]
    assert_includes key_set, @keys[1]
    key_set.remove_keys(key_set2)
    assert_not_includes key_set, @keys[0]
    assert_not_includes key_set, @keys[1]
  end

  ## JWK Tests

  def test_exports_to_JWK
    key_set = HealthCards::KeySet.new(@keys)
    jwks = JSON.parse(key_set.to_jwk)
    assert_equal 2, jwks['keys'].length
    jwks['keys'].each do |entry|
      assert_equal 'sig', entry['use']
      assert_equal 'ES256', entry['alg']
      assert_equal 'EC', entry['kty']
      assert_equal 'P-256', entry['crv']
    end
  end
end
