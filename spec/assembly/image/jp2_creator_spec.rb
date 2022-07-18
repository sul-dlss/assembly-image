# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Assembly::Image::Jp2Creator do
  subject(:result) { jp2creator.create }

  let(:jp2_output_file) { File.join(TEST_OUTPUT_DIR, 'test.jp2') }

  let(:assembly_image) { Assembly::Image.new(input_path) }
  let(:input_path) { TEST_TIF_INPUT_FILE }
  let(:jp2creator) { described_class.new(assembly_image, output: jp2_output_file) }

  before { cleanup }

  context 'when given an LZW compressed RGB tif' do
    before do
      generate_test_image(input_path, compress: 'lzw')
    end

    it 'creates the jp2 with a temp file' do
      expect(File).to exist input_path
      expect(File).not_to exist jp2_output_file
      expect(result).to be_a_kind_of Assembly::Image
      expect(result.path).to eq jp2_output_file
      expect(jp2_output_file).to have_jp2_mimetype

      # Indicates a temp tiff was not created.
      expect(jp2creator.tmp_tiff_path).not_to be_nil
      expect(result.exif.colorspace).to eq 'sRGB'
      jp2 = Assembly::Image.new(jp2_output_file)
      expect(jp2.height).to eq 36
      expect(jp2.width).to eq 43
    end
  end

  context 'when given a cmyk tif' do
    let(:input_path) { File.join(TEST_INPUT_DIR, 'test-cmyk.tif') }

    before do
      generate_test_image(input_path, color: 'cmyk', cg_type: 'cmyk', profile: 'cmyk', bands: 4)
    end

    it 'creates an srgb jp2' do
      expect(File).to exist input_path
      expect(File).not_to exist jp2_output_file
      expect(assembly_image.srgb?).to be false
      expect(assembly_image.vips_image.interpretation).to eq :cmyk
      expect(assembly_image.has_profile?).to be true
      expect(result).to be_a_kind_of Assembly::Image
      expect(result.path).to eq jp2_output_file
      expect(jp2_output_file).to have_jp2_mimetype

      # NOTE: we verify the CMYK has been converted to an SRGB JP2 correctly by using ruby-vips instead of exif,
      #   since exif does not correctly identify the color space ... and we have to verify this on the *temporary tiff*
      #  because the lipvips version available for circleci does not speak JP2
      temp_tiff_path = jp2creator.send(:make_tmp_tiff)
      tmp_tiff_image = Assembly::Image.new(temp_tiff_path)
      expect(tmp_tiff_image.srgb?).to be true
    end
  end

  context 'when the input file is a JPEG' do
    let(:input_path) { TEST_JPEG_INPUT_FILE }

    before do
      generate_test_image(TEST_JPEG_INPUT_FILE)
    end

    it 'creates jp2 when given a JPEG' do
      expect(File).to exist TEST_JPEG_INPUT_FILE
      expect(File).not_to exist jp2_output_file
      expect(result).to be_a_kind_of Assembly::Image
      expect(result.path).to eq jp2_output_file
      expect(jp2_output_file).to have_jp2_mimetype

      # Indicates a temp tiff was created.
      expect(jp2creator.tmp_tiff_path).not_to be_nil
      expect(File).not_to exist jp2creator.tmp_tiff_path
    end
  end

  describe '#make_tmp_tiff' do
    subject(:tiff_file) { jp2creator.send(:make_tmp_tiff) }

    let(:input_path) { 'spec/test_data/color_rgb_srgb_rot90cw.tif' }
    let(:vips_output) { Vips::Image.new_from_file tiff_file }
    let(:plum) { [94.0, 58.0, 101.0] }

    context 'when given a tiff with a rotation hint' do
      it 'rotates it' do
        expect(Vips::Image.new_from_file(input_path).getpoint(3, 3)).not_to eq plum
        expect(vips_output.getpoint(3, 3)).to eq plum
      end
    end
  end
end
