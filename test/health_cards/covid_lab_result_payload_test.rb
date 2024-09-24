# frozen_string_literal: true

require 'test_helper'

class COVIDLabResultPayloadTest < CommonTest
  def setup
    bundle = FHIR::Bundle.new(load_json_fixture('example-covid-lab-result-bundle'))
    @lab_result_card = HealthCards::COVIDLabResultPayload.new(bundle: bundle, issuer: 'http://example.org')
  end

  def test_is_a_custom_type
    assert @lab_result_card.is_a?(HealthCards::COVIDLabResultPayload)
  end

  def test_includes_correct_types
    HealthCards::COVIDLabResultPayload.types.include?('https://smarthealth.cards#health-card')
    HealthCards::COVIDLabResultPayload.types.include?('https://smarthealth.cards#covid19')
    HealthCards::COVIDLabResultPayload.types.include?('https://smarthealth.cards#laboratory')
  end

  def test_supports_laboratory_type
    assert HealthCards::COVIDLabResultPayload.supports_type?('https://smarthealth.cards#laboratory')
  end

  def test_minified_lab_result_entries
    bundle = @lab_result_card.strip_fhir_bundle
    assert_equal 2, bundle.entry.size
    obs = bundle.entry[1].resource

    assert_equal 'final', obs.status
    assert_equal '2021-02-17', obs.effectiveDateTime
    assert_nil obs.issued
  end
end
