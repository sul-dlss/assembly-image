# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Assembly::Image do
  let(:assembly_image) { described_class.new(input_path) }
  let(:input_path) { TEST_TIF_INPUT_FILE }

before { cleanup }

  describe '#jp2_filename' do
    it 'indicates the default jp2 filename' do
      expect(assembly_image.jp2_filename).to eq TEST_TIF_INPUT_FILE.gsub('.tif', '.jp2')
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
      before do
        generate_test_image(TEST_TIF_INPUT_FILE, compress: 'none', width: '37838', height: '37838')
      end

      it 'creates the jp2 with a temp file' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).not_to exist TEST_JP2_OUTPUT_FILE
        result = assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE)
        expect(assembly_image.tmp_path).not_to be_nil
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_OUTPUT_FILE
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
        expect(result.exif.colorspace).to eq 'sRGB'
        jp2 = described_class.new(TEST_JP2_OUTPUT_FILE)
        expect(jp2.height).to eq 37_838
        expect(jp2.width).to eq 37_838
      end
    end

    context 'when given an LZW compressed RGB tif with more than 4GB of image data', skip: 'This test will create a 4GB temporary image, so skipping by default.' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE, compress: 'lzw', width: '37838', height: '37838')
      end

      it 'creates the jp2 with a temp file' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).not_to exist TEST_JP2_OUTPUT_FILE
        expect(assembly_image.exif.samplesperpixel).to be 3
        expect(assembly_image.exif.bitspersample).to eql '8 8 8'
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2abl
        result = assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE)
        expect(assembly_image.tmp_path).not_to be_nil
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_OUTPUT_FILE
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
        expect(result.exif.colorspace).to eq 'sRGB'
        jp2 = described_class.new(TEST_JP2_OUTPUT_FILE)
        expect(jp2.height).to eq 37_838
        expect(jp2.width).to eq 37_838
      end
    end

    context 'when given a bitonal tif' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE, color: 'bin', bands: 1, depth: 1)
      end

      it 'creates grayscale jp2' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).not_to exist TEST_JP2_OUTPUT_FILE
        expect(assembly_image.exif.samplesperpixel).to be 1
        expect(assembly_image.exif.bitspersample).to be 1
        expect(assembly_image).not_to have_color_profile
        result = assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_OUTPUT_FILE
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
        # expect(result.exif.colorspace).to eq 'Grayscale'
      end
    end

    context 'when given a color tif but bitonal image data (1 channels and 1 bits per pixel)' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE, color: 'bin', bands: 3)
      end

      it 'creates color jp2' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).not_to exist TEST_JP2_OUTPUT_FILE
        expect(assembly_image).not_to have_color_profile
        expect(assembly_image.exif.samplesperpixel).to be 3
        expect(assembly_image.exif.bitspersample).to eql '8 8 8'
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        result = assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_OUTPUT_FILE
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
        expect(result.exif.colorspace).to eq 'sRGB'
      end
    end

    context 'when given a graycale tif but with bitonal image data (1 channel and 1 bits per pixel)' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE, color: 'grey', bands: 1)
      end

      it 'creates grayscale jp2' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).not_to exist TEST_JP2_OUTPUT_FILE
        expect(assembly_image).not_to have_color_profile
        expect(assembly_image.exif.samplesperpixel).to be 1
        expect(assembly_image.exif.bitspersample).to be 8
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        result = assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE)
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_OUTPUT_FILE
        # expect(result.exif.colorspace).to eq 'Grayscale'
      end
    end

    context 'when given a color tif but with greyscale image data (1 channel and 8 bits per pixel)' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE, color: 'grey')
      end

      it 'creates color jp2' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).not_to exist TEST_JP2_OUTPUT_FILE
        expect(assembly_image.exif.samplesperpixel).to be 3
        expect(assembly_image.exif.bitspersample).to eql '8 8 8'
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        expect(assembly_image).not_to have_color_profile
        result = assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_OUTPUT_FILE
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
        expect(result.exif.colorspace).to eq 'sRGB'
      end
    end

    context 'when given a cmyk tif' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE, color: 'cmyk', cg_type: 'cmyk', profile: 'cmyk', bands: 4)
      end

      it 'creates jp2' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).not_to exist TEST_JP2_OUTPUT_FILE
        expect(assembly_image.exif.samplesperpixel).to be 4
        expect(assembly_image.exif.bitspersample).to eql '8 8 8 8'
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        expect(assembly_image).to have_color_profile
        result = assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_OUTPUT_FILE
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
        # expect(result.exif.colorspace).to eq 'sRGB'
      end
    end

    context 'when the source image has no profile' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE)
      end

      it 'creates a jp2' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).not_to exist TEST_JP2_OUTPUT_FILE
        expect(assembly_image.exif.samplesperpixel).to be 3
        expect(assembly_image.exif.bitspersample).to eql '8 8 8'
        expect(assembly_image).not_to have_color_profile
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE)
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
      end
    end

    context "when the output file exists and you don't allow overwriting" do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE)
        generate_test_image(TEST_JP2_OUTPUT_FILE)
      end

      it 'does not run' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).to exist TEST_JP2_OUTPUT_FILE
        expect { assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE) }.to raise_error(SecurityError)
      end
    end

    context 'when given a test tiff' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE)
      end

      it 'gets the correct image height and width' do
        expect(assembly_image.height).to eq 36
        expect(assembly_image.width).to eq 43
      end
    end

    context 'when the input file is a jp2' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE)
      end

      it 'does not run' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).not_to exist TEST_JP2_OUTPUT_FILE
        expect(assembly_image).not_to have_color_profile
        expect(assembly_image).to be_a_valid_image
        expect(assembly_image).to be_jp2able
        assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE)
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
        jp2_file = described_class.new(TEST_JP2_OUTPUT_FILE)
        expect(jp2_file).to be_valid_image
        expect(jp2_file).not_to be_jp2able
        expect { jp2_file.create_jp2 }.to raise_error(RuntimeError)
      end
    end

    context 'when you specify a bogus output profile' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE)
      end

      it 'runs, because this is not currently an option' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        result = assembly_image.create_jp2(output_profile: 'bogusness')
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_INPUT_FILE
        expect(TEST_JP2_INPUT_FILE).to be_a_jp2
        expect(result.exif.colorspace).to eq 'sRGB'
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
      before do
        generate_test_image(TEST_TIF_INPUT_FILE)
      end

      it 'creates a jp2 of the same filename and in the same location as the input and cleans up the tmp file' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File.exist?(TEST_JP2_INPUT_FILE)).to be false
        result = assembly_image.create_jp2
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_INPUT_FILE
        expect(TEST_JP2_INPUT_FILE).to be_a_jp2
        expect(result.exif.colorspace).to eq 'sRGB'
      end
    end

    context 'when the output file exists and you allow overwriting' do
      before do
        generate_test_image(TEST_TIF_INPUT_FILE)
        generate_test_image(TEST_JP2_OUTPUT_FILE)
      end

      it 'recreates jp2' do
        expect(File).to exist TEST_TIF_INPUT_FILE
        expect(File).to exist TEST_JP2_OUTPUT_FILE
        result = assembly_image.create_jp2(output: TEST_JP2_OUTPUT_FILE, overwrite: true)
        expect(result).to be_a_kind_of described_class
        expect(result.path).to eq TEST_JP2_OUTPUT_FILE
        expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
        expect(result.exif.colorspace).to eq 'sRGB'
      end
    end
  end
end
