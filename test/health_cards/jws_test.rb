# frozen_string_literal: true

require 'test_helper'

class JWSTest < CommonTest
  def setup
    @payload = 'foo'
    @private_key = private_key
  end

  ## Constructor

  def test_JWS_can_be_created_from_string_payload
    HealthCards::JWS.new(payload: @payload)
  end

  def test_changing_keys_causes_signature_update
    jws = HealthCards::JWS.new(payload: @payload, key: @private_key)
    old_sig = jws.signature
    jws.key = HealthCards::PrivateKey.generate_key
    new_sig = jws.signature
    assert_not_equal old_sig, new_sig
  end

  def test_changing_payloads_causes_signature_update
    jws = HealthCards::JWS.new(payload: @payload, key: @private_key)
    old_sig = jws.signature
    jws.payload = 'bar'
    new_sig = jws.signature
    assert_not_equal old_sig, new_sig
  end
end
