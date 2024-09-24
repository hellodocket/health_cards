# frozen_string_literal: true

require 'test_helper'

class HealthCardTest < CommonTest
  def setup
    @jws = load_json_fixture('example-jws')
    @card = HealthCards::HealthCard.new(@jws)
  end

  def test_json
    credential = JSON.parse(@card.to_json)
    vc = credential['verifiableCredential'][0]
    assert_equal @jws, vc
  end

  def test_qr_codes
    assert_not_nil @card.code_by_ordinal(1)
  end

  def test_resource_with_type
    patient = @card.resource(type: FHIR::Patient)
    assert_equal FHIR::Patient, patient.class
  end

  def test_resources_with_type
    imms = @card.resources(type: FHIR::Immunization)
    assert_equal 2, imms.length
    imms.each do |i|
      assert_equal FHIR::Immunization, i.class
    end
  end

  def test_resource_with_type_and_rules
    lot = 'Lot #0000001'
    imms = @card.resources(type: FHIR::Immunization) { |i| i.lotNumber == lot }
    assert_equal 1, imms.length
    assert_equal lot, imms.first.lotNumber
  end

  def test_only_rules
    resources = @card.resources { |r| !r.id.nil? }
    assert_equal 0, resources.length
  end
end
