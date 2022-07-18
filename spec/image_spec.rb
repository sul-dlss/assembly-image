# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Assembly::Image do
  let(:assembly_image) { described_class.new(input_path) }
  let(:input_path) { TEST_TIF_INPUT_FILE }
  let(:jp2_output_file) { File.join(TEST_OUTPUT_DIR, File.basename(input_path).gsub('.tif', '.jp2')) }

  before { cleanup }

  describe '#jp2_filename' do
    it 'indicates the default jp2 filename' do
      expect(assembly_image.jp2_filename).to eq input_path.gsub('.tif', '.jp2')
    end

    context 'with a file with no extension' do
      let(:input_path) { '/path/to/a/file_with_no_extension' }

      it 'indicates the default jp2 filename' do
        expect(assembly_image.jp2_filename).to eq '/path/to/a/file_with_no_extension.jp2'
      end
    end
  end

  describe '#create_jp2' do
    context 'when input path is blank' do
      let(:input_path) { '' }

      it 'does not run if no input file is passed in' do
        expect { assembly_image.create_jp2 }.to raise_error(RuntimeError)
      end
    end

    context 'when given an uncompressed compressed RGB tif with more than 4GB of image data', skip: 'This test will create a 4GB test image and a 4GB temporary image, so skipping by default.' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'rgb.tif') }

      before do
        generate_test_image(input_path, compress: 'none', width: '37838', height: '37838')
      end

      it 'creates the jp2 with a temp file' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        result = assembly_image.create_jp2(output: jp2_output_file)
        expect(assembly_image.tmp_tiff_path).not_to be_nil
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq jp2_output_file
        expect(jp2_output_file).to have_jp2_mimetype
        expect(result.exif.colorspace).to eq 'sRGB'
        expect(result.height).to eq 37_838
        expect(result.width).to eq 37_838
      end
    end

    context 'when given an LZW compressed RGB tif with more than 4GB of image data', skip: 'This test will create a 4GB temporary image, so skipping by default.' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'lzw.tif') }

      before do
        generate_test_image(input_path, compress: 'lzw', width: '37838', height: '37838')
      end

      it 'creates the jp2 with a temp file' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.exif.samplesperpixel).to be 3
        expect(assembly_image.exif.bitspersample).to eql '8 8 8'
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2abl
        result = assembly_image.create_jp2(output: jp2_output_file)
        expect(assembly_image.tmp_tiff_path).not_to be_nil
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq jp2_output_file
        expect(jp2_output_file).to have_jp2_mimetype
        expect(result.exif.colorspace).to eq 'sRGB'
        expect(result.height).to eq 37_838
        expect(result.width).to eq 37_838
      end
    end

    context 'when given a bitonal tif' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'bitonal.tif') }

      before do
        generate_test_image(input_path, color: 'bin', bands: 1, depth: 1)
      end

      it 'creates valid jp2' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.exif.samplesperpixel).to be 1
        expect(assembly_image.exif.bitspersample).to be 1
        expect(assembly_image).not_to have_color_profile
        result = assembly_image.create_jp2(output: jp2_output_file)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq jp2_output_file
        expect(jp2_output_file).to have_jp2_mimetype
        expect(result.exif.colorspace).to eq 'Grayscale'
      end
    end

    context 'when given a color tif but bitonal image data (1 channels and 1 bits per pixel)' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'color.tif') }

      before do
        generate_test_image(input_path, color: 'bin', bands: 3)
      end

      it 'creates color jp2' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        expect(assembly_image).not_to have_color_profile
        expect(assembly_image.exif.samplesperpixel).to be 3
        expect(assembly_image.exif.bitspersample).to eql '8 8 8'
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        result = assembly_image.create_jp2(output: jp2_output_file)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq jp2_output_file
        expect(jp2_output_file).to have_jp2_mimetype
        expect(result.exif.colorspace).to eq 'sRGB'
      end
    end

    context 'when given a graycale tif but with bitonal image data (1 channel and 1 bits per pixel)' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'gray.tif') }

      before do
        generate_test_image(input_path, color: 'grey', bands: 1)
      end

      it 'creates grayscale jp2' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        expect(assembly_image).not_to have_color_profile
        expect(assembly_image.exif.samplesperpixel).to be 1
        expect(assembly_image.exif.bitspersample).to be 8
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        result = assembly_image.create_jp2(output: jp2_output_file)
        expect(jp2_output_file).to have_jp2_mimetype
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq jp2_output_file
        expect(result.exif.colorspace).to eq 'Grayscale'
      end
    end

    context 'when given a color tif but with greyscale image data (1 channel and 8 bits per pixel)' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'color_gray.tif') }

      before do
        generate_test_image(input_path, color: 'grey')
      end

      it 'creates color jp2' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.exif.samplesperpixel).to be 3
        expect(assembly_image.exif.bitspersample).to eql '8 8 8'
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        expect(assembly_image).not_to have_color_profile
        result = assembly_image.create_jp2(output: jp2_output_file)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq jp2_output_file
        expect(jp2_output_file).to have_jp2_mimetype
        expect(result.exif.colorspace).to eq 'sRGB'
      end
    end

    context 'when given a cmyk tif' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'cmky.tif') }

      before do
        generate_test_image(input_path, color: 'cmyk', cg_type: 'cmyk', profile: 'cmyk', bands: 4)
      end

      it 'creates an srgb jp2', skip: 'Need to verify the color space is correct in jp2' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.exif.samplesperpixel).to be 4
        expect(assembly_image.exif.bitspersample).to eql '8 8 8 8'
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        expect(assembly_image).to have_color_profile
        result = assembly_image.create_jp2(output: jp2_output_file)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq jp2_output_file
        expect(jp2_output_file).to have_jp2_mimetype
        # note, we verify the CMYK has been converted to an SRGB JP2 correctly by using ruby-vips instead of exif, since exif does not correctly
        #  identify the color space...note: this line current does not work in circleci, potentially due to libvips version differences
        expect(Vips::Image.new_from_file(jp2_output_file).get_value('interpretation')).to eq :srgb
      end
    end

    context 'when the source image has no profile' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'no_profile.tif') }

      before do
        generate_test_image(input_path)
      end

      it 'creates a jp2' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.exif.samplesperpixel).to be 3
        expect(assembly_image.exif.bitspersample).to eql '8 8 8'
        expect(assembly_image).not_to have_color_profile
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        assembly_image.create_jp2(output: jp2_output_file)
        expect(jp2_output_file).to have_jp2_mimetype
      end
    end

    context "when the output file exists and you don't allow overwriting" do
      before do
        generate_test_image(input_path)
        FileUtils.touch(jp2_output_file) # just need a file with this name, don't care what
      end

      it 'does not run' do
        expect(File).to exist input_path
        expect(File).to exist jp2_output_file
        expect { assembly_image.create_jp2(output: jp2_output_file) }.to raise_error(SecurityError)
      end
    end

    context 'when given a test tiff' do
      before do
        generate_test_image(input_path)
      end

      it 'gets the correct image height and width' do
        expect(assembly_image.height).to eq 36
        expect(assembly_image.width).to eq 43
      end
    end

    context 'when the input file is a jp2' do
      before do
        generate_test_image(input_path)
      end

      it 'does not run' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        expect(assembly_image).not_to have_color_profile
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        assembly_image.create_jp2(output: jp2_output_file)
        expect(jp2_output_file).to have_jp2_mimetype
        jp2_file = described_class.new(jp2_output_file)
        expect(jp2_file).to be_valid_image
        expect(jp2_file).not_to be_jp2able
        expect { jp2_file.create_jp2 }.to raise_error(RuntimeError)
      end
    end

    context 'when an invalid tmp folder' do
      before do
        generate_test_image(TEST_JPEG_INPUT_FILE)
      end

      let(:input_path) { TEST_JPEG_INPUT_FILE }

      it 'does not run' do
        bogus_folder = '/crapsticks'
        expect(File).to exist TEST_JPEG_INPUT_FILE
        expect(File).not_to exist bogus_folder
        expect { assembly_image.create_jp2(tmp_folder: bogus_folder) }.to raise_error(RuntimeError)
      end
    end

    context 'when no output file is specified' do
      let(:jp2_input_file) { File.join(TEST_INPUT_DIR, 'test.jp2') }

      before do
        generate_test_image(input_path)
      end

      it 'creates a jp2 of the same filename and in the same location as the input and cleans up the tmp file' do
        expect(File).to exist input_path
        expect(File.exist?(jp2_input_file)).to be false
        result = assembly_image.create_jp2
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq jp2_input_file
        expect(jp2_input_file).to have_jp2_mimetype
        expect(result.exif.colorspace).to eq 'sRGB'
      end
    end

    context 'when the output file exists and you allow overwriting' do
      before do
        generate_test_image(input_path)
        FileUtils.touch(jp2_output_file) # just need a file with this name, don't care what
      end

      it 'recreates jp2' do
        expect(File).to exist input_path
        expect(File).to exist jp2_output_file
        result = assembly_image.create_jp2(output: jp2_output_file, overwrite: true)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq jp2_output_file
        expect(jp2_output_file).to have_jp2_mimetype
        expect(result.exif.colorspace).to eq 'sRGB'
      end
    end
  end
end
