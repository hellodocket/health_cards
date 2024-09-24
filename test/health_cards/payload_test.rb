# frozen_string_literal: true

require 'test_helper'

class PayloadTest < CommonTest
  class TestCOVIDLabPayload < HealthCards::Payload
    additional_types 'https://smarthealth.cards#covid19'
    additional_types 'https://smarthealth.cards#laboratory'
  end

  def setup
    # from https://smarthealth.cards/examples/example-00-d-jws.txt

    @issuer = 'https://smarthealth.cards/examples/issuer'
    @bundle = bundle_payload

    file = File.read('test/fixtures/files/example-verbose-jws-payload.json')
    @bundle = FHIR.from_contents(file)
    @health_card = HealthCards::Payload.new(issuer: @issuer, bundle: @bundle)
  end

  ## Constructor

  def test_payload_can_be_created_from_a_bundle
    assert_not_nil @health_card.bundle
    assert @health_card.bundle.is_a?(FHIR::Bundle)
  end

  def test_payload_can_be_created_without_allows
    bundle = FHIR.from_contents(File.read('test/fixtures/files/example-covid-lab-result-bundle.json'))
    test_card = TestCOVIDLabPayload.new(issuer: @issuer, bundle: bundle)
    test_card.to_hash
    test_card.to_hash(filter: false)
  end

  def test_payload_handles_empty_paylods
    compressed_payload = HealthCards::Payload.compress_payload(FHIR::Bundle.new.to_json)
    jws = HealthCards::JWS.new(header: {}, payload: compressed_payload, key: private_key)
    assert_raises HealthCards::InvalidCredentialError do
      HealthCards::HealthCard.new(jws.to_s)
    end
  end

  ## Creating a Payload from a JWS

  def test_payload_can_be_created_from_jws
    jws_string = load_json_fixture('example-jws')
    card = HealthCards::HealthCard.new(jws_string)
    assert_not_nil card.bundle
    assert card.bundle.is_a?(FHIR::Bundle)
  end

  def test_payload_throws_an_exception_when_the_payload_is_not_a_FHIR_bundle
    assert_raises HealthCards::InvalidPayloadError do
      HealthCards::Payload.new(issuer: @issuer, bundle: FHIR::Patient.new)
    end

    assert_raises HealthCards::InvalidPayloadError do
      HealthCards::Payload.new(issuer: @issuer, bundle: '{"foo": "bar"}')
    end

    assert_raises HealthCards::InvalidPayloadError do
      HealthCards::Payload.new(issuer: @issuer, bundle: 'foo')
    end
  end

  def test_includes_required_credential_attributes_in_json
    hash = JSON.parse(@health_card.to_json)

    assert_equal @issuer, hash['iss']
    assert hash['nbf'] >= Time.now.to_i

    type = hash.dig('vc', 'type')
    assert_not_nil type
    assert_includes type, 'https://smarthealth.cards#health-card'
    bundle = hash.dig('vc', 'credentialSubject', 'fhirBundle')

    assert_not_nil bundle
    FHIR::Bundle.new(bundle)
  end

  def test_export_with_unfiltered_bundle
    hash = @health_card.to_hash(filter: false)
    bundle = hash.dig(:vc, :credentialSubject, :fhirBundle)

    assert_not_nil bundle
    assert_not_nil bundle['entry']
    resources = bundle['entry'].map { |e| e['resource'] }
    assert_not_nil resources[0]['telecom']
    assert_not_nil resources[1].dig('code', 'coding')[0]['display']
    assert_not_nil resources[2].dig('code', 'text')
  end

  def test_redefine_uris_populates_BundleentryfullUrl_elements_with_short_resource_scheme_URIs
    stripped_bundle = @health_card.strip_fhir_bundle

    resource_nums = []
    new_entries = stripped_bundle.entry
    new_entries.each do |resource|
      url = resource.fullUrl
      resource, num = url.split(':')
      assert_equal('resource', resource)
      resource_nums.push(num)
    end

    inc_array = Array.new(new_entries.length, &:to_s)
    assert_equal(resource_nums, inc_array)
  end

  def test_changes_to_strpped_bundle_do_not_affect_bundle_values
    original_json = @health_card.to_json
    @health_card.strip_fhir_bundle
    original_json2 = @health_card.to_json
    assert_equal original_json, original_json2
  end

  def test_do_not_strp_name_text_elements
    stripped_bundle = @health_card.strip_fhir_bundle
    assert_not_nil stripped_bundle.entry[0].resource.name[0].text
  end

  def test_update_elements_strips_resource_level_id_meta_text_elements_from_fhir_bundle
    stripped_bundle = @health_card.strip_fhir_bundle
    stripped_entries = stripped_bundle.entry

    stripped_entries.each do |entry|
      resource = entry.resource
      assert(!resource.id, "#{resource} has id")
      assert(!resource.text, "#{resource} has text")
      meta = resource.meta
      if meta
        assert_equal 1, meta.to_hash.length
        assert_not_nil meta.security
      end
    end
  end

  def test_supports_single_type
    assert HealthCards::Payload.supports_type?('https://smarthealth.cards#health-card')
  end

  def test_update_nested_elements_strips_any_codeableconcept_text_and_display_elements_from_fhir_bundle
    stripped_bundle = @health_card.strip_fhir_bundle
    stripped_resources = stripped_bundle.entry

    resource_with_codeable_concept = stripped_resources[2]
    codeable_concept = resource_with_codeable_concept.resource.valueCodeableConcept
    coding = codeable_concept.coding[0]

    assert_nil codeable_concept.text
    assert_nil coding.display
  end

  def test_update_nested_elements_populates_reference_reference_elements_with_short_resource_scheme_uris
    stripped_bundle = @health_card.strip_fhir_bundle
    stripped_resources = stripped_bundle.entry
    resource_with_reference = stripped_resources[2]

    reference = resource_with_reference.resource.subject.reference

    assert_match(/resource:[0-9]+/, reference)
  end

  def test_all_reference_types_are_replaced_with_short_resource_scheme_URIs
    bundle = FHIR::Bundle.new(load_json_fixture('example-logical-link-bundle'))
    card = HealthCards::Payload.new(issuer: 'http://example.org/fhir', bundle: bundle)
    new_bundle = card.strip_fhir_bundle

    assert_entry_references_match(new_bundle.entry[0], new_bundle.entry[2].resource.subject) # logical ref
    assert_entry_references_match(new_bundle.entry[0], new_bundle.entry[3].resource.subject) # full url ref
    assert_entry_references_match(new_bundle.entry[1], new_bundle.entry[4].resource.subject) # uuid ref
  end

  # Helper function
  def assert_entry_references_match(patient_entry, reference_element)
    patient_url = patient_entry.fullUrl
    ref_url = reference_element.reference

    assert_not_nil patient_url
    assert_equal patient_url, ref_url
  end

  def test_raises_error_when_url_referes_to_resource_outside_bundle
    bundle = FHIR::Bundle.new(load_json_fixture('example-logical-link-bundle-bad'))
    card = HealthCards::Payload.new(issuer: 'http://example.org/fhir', bundle: bundle)
    assert_raises HealthCards::InvalidBundleReferenceError do
      card.strip_fhir_bundle
    end
  end

  def test_compress_payload_applies_a_raw_deflate_compression_and_allows_for_the_original_payload_to_be_restored
    original_hc = HealthCards::Payload.new(issuer: @issuer, bundle: FHIR::Bundle.new)
    new_hc = HealthCards::Payload.from_payload(original_hc.to_s)
    assert_equal original_hc.to_hash, new_hc.to_hash
  end
end
