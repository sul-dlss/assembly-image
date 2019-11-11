# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

# rubocop:disable Metrics/BlockLength
describe Assembly::Image do
  it 'does not run if no input file is passed in' do
    @ai = Assembly::Image.new('')
    expect{ @ai.create_jp2 }.to raise_error(RuntimeError)
  end

  it 'indicates the default jp2 filename' do
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.jp2_filename).to eq TEST_TIF_INPUT_FILE.gsub('.tif', '.jp2')
  end

  it 'indicates the default jp2 filename' do
    @ai = Assembly::Image.new('/path/to/a/file_with_no_extension')
    expect(@ai.jp2_filename).to eq '/path/to/a/file_with_no_extension.jp2'
  end

  it 'creates jp2 with a temp file when given an LZW compressed RGB tif' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE, profile: 'AdobeRGB1998', compression: 'lzw')
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.exif.samplesperpixel).to eql 3
    expect(@ai.exif.bitspersample).to eql '8 8 8'
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'creates jp2 when the source image has no profile' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.exif.samplesperpixel).to eql 3
    expect(@ai.exif.bitspersample).to eql '8 8 8'
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    expect(@ai).to_not have_color_profile
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'creates jp2 when the source image is cmyk tiff' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE, color: 'cmyk', cg_type: 'cmyk', profile: 'cmyk', bands: 4)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.exif.samplesperpixel).to eql 4
    expect(@ai.exif.bitspersample).to eql '8 8 8 8'
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    expect(@ai).to have_color_profile
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    # expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'creates color jp2 when given a color tif but with greyscale image data.' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE, color: 'grey')
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.exif.samplesperpixel).to eql 3
    expect(@ai.exif.bitspersample).to eql '8 8 8'
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    expect(@ai).to_not have_color_profile
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'creates color jp2 when given a color tif but bitonal image data' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE, color: 'bin', bands: 3)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.exif.samplesperpixel).to eql 3
    expect(@ai.exif.bitspersample).to eql '8 8 8'
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    expect(@ai).to_not have_color_profile
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'creates greyscale jp2 when given a graycale tif' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE, color: 'grey', bands: 1)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.exif.samplesperpixel).to eql 1
    expect(@ai.exif.bitspersample).to eql 8
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    expect(@ai).to_not have_color_profile
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    # expect(result.exif.colorspace).to eq 'Grayscale'
  end

  it 'creates jp2 when given a graycale tif but with bitonal image data' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE, color: 'bin', bands: 1)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.exif.samplesperpixel).to eql 1
    expect(@ai.exif.bitspersample).to eql 8
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    expect(@ai).to_not have_color_profile
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    # expect(result.exif.colorspace).to eq 'Grayscale'
  end

  it 'creates jp2 when given a bitonal tif' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE, color: 'bin', bands: 1, depth: 1)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.exif.samplesperpixel).to eql 1
    expect(@ai.exif.bitspersample).to eql 1
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    expect(@ai).to_not have_color_profile
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    # expect(result.exif.colorspace).to eq 'Grayscale'
  end

  it 'gets the correct image height and width' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE)
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.height).to eq 36
    expect(@ai.width).to eq 43
  end

  it 'recreates jp2 if the output file exists and if you allow overwriting' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE)
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE, overwrite: true)
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it "does not run if the output file exists and you don't allow overwriting" do
    generate_vips_test_image(TEST_TIF_INPUT_FILE)
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect{ @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE) }.to raise_error(SecurityError)
  end

  it 'does not run if the input file is a jp2' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_INPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    # Indicates a temp tiff was not created.
    expect(@ai.tmp_path).to be_nil
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    @ai.create_jp2(output: TEST_JP2_INPUT_FILE)
    expect(TEST_JP2_INPUT_FILE).to be_a_jp2
    @ai = Assembly::Image.new(TEST_JP2_INPUT_FILE)
    expect(@ai).to be_valid_image
    expect(@ai).to_not be_jp2able
    expect { @ai.create_jp2 }.to raise_error(RuntimeError)
  end

  it 'runs if you specify a bogus output profile, because this is not currently an option' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result = @ai.create_jp2(output_profile: 'bogusness')
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_INPUT_FILE
    expect(TEST_JP2_INPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'creates jp2 when given a JPEG' do
    generate_vips_test_image(TEST_JPEG_INPUT_FILE)
    expect(File).to exist TEST_JPEG_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_JPEG_INPUT_FILE)
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    # Indicates a temp tiff was created.
    expect(@ai.tmp_path).not_to be_nil
    expect(File).not_to exist @ai.tmp_path
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
  end

  it 'does not run if you specify a bogus tmp folder' do
    generate_vips_test_image(TEST_JPEG_INPUT_FILE)
    bogus_folder = '/crapsticks'
    expect(File).to exist TEST_JPEG_INPUT_FILE
    expect(File).to_not exist bogus_folder
    @ai = Assembly::Image.new(TEST_JPEG_INPUT_FILE)
    expect { @ai.create_jp2(tmp_folder: bogus_folder) }.to raise_error(RuntimeError)
  end

  it 'creates a jp2 and preserve the temporary file if specified' do
    generate_vips_test_image(TEST_JPEG_INPUT_FILE)
    expect(File).to exist TEST_JPEG_INPUT_FILE
    @ai = Assembly::Image.new(TEST_JPEG_INPUT_FILE)
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE, preserve_tmp_source: true)
    # Indicates a temp tiff was created.
    expect(@ai.tmp_path).not_to be_nil
    expect(File).to exist @ai.tmp_path
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(File.exist?(@ai.tmp_path)).to be true
  end

  it 'creates a jp2 of the same filename and in the same location as the input if no output file is specified, and should cleanup tmp file' do
    generate_vips_test_image(TEST_TIF_INPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File.exist?(TEST_JP2_INPUT_FILE)).to be false
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result = @ai.create_jp2
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_INPUT_FILE
    expect(TEST_JP2_INPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'creates the jp2 with a temp file when given an uncompressed compressed RGB tif with more than 4GB of image data' do
    skip 'This test will create a 4GB test image and a 4GB temporary image, so skipping by default.'
    generate_test_image(TEST_TIF_INPUT_FILE, compress: 'none', width: '37838', height: '37838')
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
    @jp2 = Assembly::Image.new(TEST_JP2_OUTPUT_FILE)
    expect(@jp2.height).to eq 37_838
    expect(@jp2.width).to eq 37_838
  end

  it 'creates the jp2 with a temp file when given an LZW compressed RGB tif with more than 4GB of image data' do
    skip 'This test will create a 4GB temporary image, so skipping by default.'
    generate_test_image(TEST_TIF_INPUT_FILE, compress: 'lzw', width: '37838', height: '37838')
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result = @ai.create_jp2(output: TEST_JP2_OUTPUT_FILE)
    expect(@ai.tmp_path).to_not be_nil
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
    @jp2 = Assembly::Image.new(TEST_JP2_OUTPUT_FILE)
    expect(@jp2.height).to eq 37_838
    expect(@jp2.width).to eq 37_838
  end

  after(:each) do
    # after each test, empty out the input and output test directories
    remove_files(TEST_INPUT_DIR)
    remove_files(TEST_OUTPUT_DIR)
  end
end
# rubocop:enable Metrics/BlockLength
