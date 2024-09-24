# frozen_string_literal: true
require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  add_filter '/test/'
  add_filter '/config/'
end

require "minitest/autorun"
require "minitest/mock"
require "json"
require "fhir_models"
require "health_cards"

class CommonTest < Minitest::Test
  def load_json_fixture(file_name)
    JSON.parse(File.read("test/fixtures/files/#{file_name}.json"))
  end

  def assert_not_nil(v)
    assert(!v.nil?)
  end

  def assert_not_equal(a, b)
    assert(a != b)
  end

  def assert_not_includes(haystack, needle)
    assert !haystack.include?(needle)
  end

  def assert_not_empty(v)
    assert(!v.empty?)
  end

  def assert_fhir(obj, type: nil, validate: true)
    output = FHIR.from_contents(obj)
    assert output.is_a?(type) if type
    assert output.valid?, output.validate if validate
    output
  end

  def bundle_payload
    bundle = FHIR::Bundle.new(type: 'collection')
    bundle.entry << FHIR::Bundle::Entry.new(fullUrl: 'http://patient/1', resource: FHIR::Patient.new)
    bundle
  end

  ## Key operations
  def cleanup_keys
    FileUtils.rm_rf key_path if File.exist?(key_path)
  end

  def key_path
    "test/tmp/test_key"
  end

  def private_key
    HealthCards::PrivateKey.load_from_or_create_from_file(key_path)
  end

  def public_key
    ""
  end

  def issuer
    pk = HealthCards::PrivateKey.load_from_or_create_from_file(key_path)
    HealthCards::Issuer.new(url: 'http://example.org', key: pk)
  end
end
