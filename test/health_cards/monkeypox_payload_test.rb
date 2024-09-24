# frozen_string_literal: true

require 'test_helper'

class MonkeypoxPayloadTest < CommonTest
  def setup
    @bundle = FHIR::Bundle.new(load_json_fixture('example-monkeypox-immunization-bundle'))
    @card = HealthCards::MonkeypoxPayload.new(bundle: @bundle, issuer: 'http://example.org')
  end

  class MonkeypoxHealthCardSame < HealthCards::MonkeypoxPayload; end

  class MonkeypoxHealthCardChanged < HealthCards::MonkeypoxPayload
    fhir_version '4.0.2'
    additional_types 'https://smarthealth.cards#test'
  end

  def test_is_a_custom_type
    assert @card.is_a?(HealthCards::MonkeypoxPayload)
  end

  def test_includes_correct_types
    assert_includes HealthCards::MonkeypoxPayload.types, 'https://smarthealth.cards#health-card'
    assert_includes HealthCards::MonkeypoxPayload.types, 'https://smarthealth.cards#monkeypox'
  end

  def test_includes_required_credential_attributes_in_hash
    hash = @card.to_hash
    type = hash.dig(:vc, :type)
    assert_not_nil type
    assert_includes type, 'https://smarthealth.cards#health-card'
    assert_includes type, 'https://smarthealth.cards#monkeypox'

    fhir_version = hash.dig(:vc, :credentialSubject, :fhirVersion)
    assert_not_nil fhir_version
    assert_equal HealthCards::MonkeypoxPayload.fhir_version, fhir_version
  end

  def test_bundle_creation
    @card = issuer.issue_health_card(@bundle, type: HealthCards::MonkeypoxPayload)
    bundle = @card.bundle
    assert_equal 3, bundle.entry.size
    assert_equal 'collection', bundle.type

    patient = bundle.entry[0].resource
    assert_equal FHIR::Patient, patient.class
    assert patient.valid?

    bundle.entry[1..3].map(&:resource).each do |imm|
      assert_equal FHIR::Immunization, imm.class
      # FHIR Validator thinks references are invalid so can't validate Immunization
    end
  end

  def test_valid_bundle_json
    assert_fhir(@card.bundle.to_json, type: FHIR::Bundle, validate: false)
  end

  def test_supports_multiple_types
    assert HealthCards::MonkeypoxPayload.supports_type? [
      'https://smarthealth.cards#health-card', 'https://smarthealth.cards#monkeypox'
    ]
  end

  def test_minified_patient_entries
    bundle = @card.strip_fhir_bundle
    assert_equal 3, bundle.entry.size
    patient = bundle.entry[0].resource

    assert_equal 'Jane', patient.name.first.given.first
    assert_equal '1961-01-20', patient.birthDate
    assert_nil patient.gender
    assert_equal 'ghp-example', patient.identifier[0].value
  end

  def test_inheritance_of_attributes
    assert_equal HealthCards::MonkeypoxPayload.types, MonkeypoxHealthCardSame.types
    assert_equal HealthCards::MonkeypoxPayload.fhir_version, MonkeypoxHealthCardSame.fhir_version
    assert_equal 1, HealthCards::Payload.types.length
    assert_equal 2, HealthCards::MonkeypoxPayload.types.length
    assert_equal 3, MonkeypoxHealthCardChanged.types.length
    assert_equal HealthCards::MonkeypoxPayload.types.length + 1, MonkeypoxHealthCardChanged.types.length
    assert_includes MonkeypoxHealthCardChanged.types, 'https://smarthealth.cards#test'
    assert_equal '4.0.2', MonkeypoxHealthCardChanged.fhir_version
  end
end
