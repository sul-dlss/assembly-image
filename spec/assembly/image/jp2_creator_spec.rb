# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Assembly::Image::Jp2Creator do
  subject(:result) { creator.create }

  let(:ai) { Assembly::Image.new(input_path) }
  let(:input_path) { TEST_TIF_INPUT_FILE }
  let(:creator) { described_class.new(ai, output: TEST_JP2_OUTPUT_FILE) }

  before { cleanup }

  context 'when given an LZW compressed RGB tif' do
    before do
      generate_test_image(TEST_TIF_INPUT_FILE, compress: 'lzw')
    end

    it 'creates the jp2 with a temp file' do
      expect(File).to exist TEST_TIF_INPUT_FILE
      expect(File).not_to exist TEST_JP2_OUTPUT_FILE
      expect(result).to be_a_kind_of Assembly::Image
      expect(result.path).to eq TEST_JP2_OUTPUT_FILE
      expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2

      # Indicates a temp tiff was not created.
      expect(creator.tmp_path).not_to be_nil
      expect(result.exif.colorspace).to eq 'sRGB'
      jp2 = Assembly::Image.new(TEST_JP2_OUTPUT_FILE)
      expect(jp2.height).to eq 36
      expect(jp2.width).to eq 43
    end
  end

  context 'when the input file is a JPEG' do
    before do
      generate_test_image(TEST_JPEG_INPUT_FILE)
    end

    let(:input_path) { TEST_JPEG_INPUT_FILE }

    it 'creates jp2 when given a JPEG' do
      expect(File).to exist TEST_JPEG_INPUT_FILE
      expect(File).not_to exist TEST_JP2_OUTPUT_FILE
      expect(result).to be_a_kind_of Assembly::Image
      expect(result.path).to eq TEST_JP2_OUTPUT_FILE
      expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2

      # Indicates a temp tiff was created.
      expect(creator.tmp_path).not_to be_nil
      expect(File).not_to exist creator.tmp_path
    end
  end
end
