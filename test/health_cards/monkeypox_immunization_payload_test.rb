# frozen_string_literal: true

require 'test_helper'

class MonkeypoxImmunizationPayloadTest < CommonTest
  def setup
    bundle = FHIR::Bundle.new(load_json_fixture('example-monkeypox-immunization-bundle'))
    @payload = HealthCards::MonkeypoxImmunizationPayload.new(bundle: bundle, issuer: 'http://example.org')
  end

  def test_is_a_custom_type
    assert @payload.is_a?(HealthCards::MonkeypoxImmunizationPayload)
  end

  def test_includes_correct_types
    assert_includes HealthCards::MonkeypoxImmunizationPayload.types, 'https://smarthealth.cards#health-card'
    assert_includes HealthCards::MonkeypoxImmunizationPayload.types, 'https://smarthealth.cards#monkeypox'
    assert_includes HealthCards::MonkeypoxImmunizationPayload.types, 'https://smarthealth.cards#immunization'
  end

  def test_supports_immunization_type
    assert HealthCards::MonkeypoxImmunizationPayload.supports_type?('https://smarthealth.cards#immunization')
  end

  def test_minified_immunization_entries
    bundle = @payload.strip_fhir_bundle
    imm = bundle.entry[1].resource

    assert_equal '206', imm.vaccineCode.coding.first.code
    assert_equal '0000002', imm.lotNumber
    assert_equal 'ABC General Hospital', imm.performer[0].actor.display
    assert_nil imm.primarySource
  end
end
