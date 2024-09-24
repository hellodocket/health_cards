# frozen_string_literal: true
require 'test_helper'
require 'health_cards/chunking_utils'

JWS_SMALL = 's' * 1195
JWS_LARGE = 'l' * 1196
JWS_3 = "#{'t' * 1191 * 2}t"

FILEPATH_NUMERIC_QR_CODE = 'example-numeric-qr-code'
FILEPATH_NUMERIC_QR_CODE_MULTIPLE = 'example-numeric-qr-code-multiple'
FILEPATH_JWS = 'example-jws'
FILEPATH_JWS_MULTIPLE = 'example-jws-multiple'

class ChunkingTest < CommonTest
  def test_individual_chunks_of_split_up_JWS_have_string_sizes_of_under_1191_characters
    large_jws_split = HealthCards::ChunkingUtils.split_jws(JWS_LARGE)
    large_jws_split.each do |chunk|
      assert_operator(1191, :>=, chunk.length)
    end
  end

  def test_JWS_size_lte_1195_returns_only_one_chunk
    small_jws_split = HealthCards::ChunkingUtils.jws_to_qr_chunks(JWS_SMALL)
    assert_equal(1, small_jws_split.length)
  end

  def test_jws_gt_1195_returns_multiple_chunks
    large_jws_split = HealthCards::ChunkingUtils.jws_to_qr_chunks(JWS_LARGE)
    assert_operator(1, :<, large_jws_split.length)
  end

  def test_JWS_size_3_chunks_returns_3_chunks
    thrice_jws_split = HealthCards::ChunkingUtils.jws_to_qr_chunks(JWS_3)
    assert_equal(3, thrice_jws_split.length)
  end

  def test_JWS_size_lte_1195_returns_one_QR_chunk
    small_qr_chunk = HealthCards::ChunkingUtils.jws_to_qr_chunks(JWS_SMALL)
    assert_equal(1, small_qr_chunk.length)
    expected_result = ["shc:/#{JWS_SMALL.chars.map { |c| format('%02d', c.ord - 45) }.join}"]
    assert_equal(expected_result, small_qr_chunk)
  end

  def test_JWS_size_3_chunks_returns_3_QR_chunks
    qr_chunks = HealthCards::ChunkingUtils.jws_to_qr_chunks(JWS_3)
    assert_equal(3, qr_chunks.length)

    expected_result = HealthCards::ChunkingUtils.split_jws(JWS_3).map.with_index(1) do |c, i|
      "shc:/#{i}/3/#{c.chars.map { |ch| format('%02d', ch.ord - 45) }.join}"
    end
    assert_equal(expected_result, qr_chunks)
  end

  def test_single_numeric_QR_code_returns_assembled_JWS
    qr_chunks = load_json_fixture(FILEPATH_NUMERIC_QR_CODE)
    expected_jws = load_json_fixture(FILEPATH_JWS)
    assembled_jws = HealthCards::ChunkingUtils.qr_chunks_to_jws qr_chunks
    assert_equal expected_jws, assembled_jws
  end

  def test_multiple_QR_codes_return_JWS
    qr_chunks = load_json_fixture(FILEPATH_NUMERIC_QR_CODE_MULTIPLE)
    expected_jws = load_json_fixture(FILEPATH_JWS_MULTIPLE)

    assembled_jws = HealthCards::ChunkingUtils.qr_chunks_to_jws qr_chunks
    assert_equal expected_jws, assembled_jws
  end
end
