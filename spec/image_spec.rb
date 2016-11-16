require 'spec_helper'

describe Assembly::Image do

  it 'should not run if no input file is passed in' do
    @ai=Assembly::Image.new('')
    expect{@ai.create_jp2}.to raise_error
  end

  it 'should indicate the default jp2 filename' do
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.jp2_filename).to eq TEST_TIF_INPUT_FILE.gsub('.tif','.jp2')
  end

  it 'should indicate the default jp2 filename' do
    @ai = Assembly::Image.new('/path/to/a/file_with_no_extension')
    expect(@ai.jp2_filename).to eq '/path/to/a/file_with_no_extension.jp2'
  end

  it 'should indicate the default DPG jp2 filename' do
    @ai = Assembly::Image.new(TEST_DPG_TIF_INPUT_FILE)
    expect(@ai.dpg_jp2_filename).to eq TEST_DPG_TIF_INPUT_FILE.gsub('.tif','.jp2').gsub('_00_','_05_')
  end

  it 'should indicate the default jp2 filename' do
    @ai = Assembly::Image.new('/path/to/a/file_with_no_00_extension')
    expect(@ai.dpg_jp2_filename).to eq '/path/to/a/file_with_no_05_extension.jp2'
  end

  it 'should create jp2 when given an RGB tif' do
    generate_test_image(TEST_TIF_INPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
    @jp2=Assembly::Image.new(TEST_JP2_OUTPUT_FILE)
    expect(@jp2.height).to eq 100
    expect(@jp2.width).to eq 100
  end

  it 'should create grayscale jp2 when given a bitonal tif' do
    skip 'The latest version of Kakadu may require some changes for this work correctly'
    # error message is        
      #  JP2 creation command failed: kdu_compress   -precise -no_weights -quiet Creversible=no Cmodes=BYPASS Corder=RPCL Cblk=\{64,64\} Cprecincts=\{256,256\},\{256,256\},\{128,128\} ORGgen_plt=yes -rate 1.5 Clevels=5  Clayers=2 -i '/tmp/408d3740-e25f-4c1b-889f-3f138d088fe4.tif' -o '/home/travis/build/sul-dlss/assembly-image/spec/test_data/output/test.jp2' with result Kakadu Error:
      #  The number of colours associated with the colour space identified by the source
      #  file (possible from an embedded ICC profile) is not consistent with the number
      #  of supplied image components and/or colour palette.  You can address this
      #  problem by supplying a `-jp2_space' or `-jpx_space' argument to explicitly
      #  identify a colour space that has anywhere from 1 to 1 colour components.
    generate_test_image(TEST_TIF_INPUT_FILE,:color=>'white',:image_type=>'Bilevel')
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai).to have_color_profile
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'Grayscale'
  end

  it 'should create color jp2 when given a color tif but bitonal image data (1 channels and 1 bits per pixel)' do
    generate_test_image(TEST_TIF_INPUT_FILE,:color=>'white',:image_type=>'TrueColor',:profile=>'')
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai).to_not have_color_profile
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'should create grayscale jp2 when given a graycale tif but with bitonal image data (1 channel and 1 bits per pixel)' do
    generate_test_image(TEST_TIF_INPUT_FILE,:color=>'white',:image_type=>'Grayscale',:profile=>'')
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai).to_not have_color_profile
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'Grayscale'
  end

  it 'should create color jp2 when given a color tif but with greyscale image data (1 channel and 8 bits per pixel)' do
    generate_test_image(TEST_TIF_INPUT_FILE,:color=>'gray',:image_type=>'TrueColor',:profile=>'')
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai).to_not have_color_profile
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'should create a jp2 when the source image has no profile' do
    generate_test_image(TEST_TIF_INPUT_FILE,:profile=>'') # generate a test input with no profile
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai).to_not have_color_profile
    expect(@ai).to be_a_valid_image
    expect(@ai).to be_jp2able
    @ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
  end

  it "should not run if the output file exists and you don't allow overwriting" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    generate_test_image(TEST_JP2_OUTPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect{@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)}.to raise_error(SecurityError)
  end

  it 'should get the correct image height and width' do
    generate_test_image(TEST_TIF_INPUT_FILE)
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect(@ai.height).to eq 100
    expect(@ai.width).to eq 100
  end

  it 'should not run if the input file is a jp2' do
    generate_test_image(TEST_JP2_OUTPUT_FILE)
    expect(File).to exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_JP2_OUTPUT_FILE)
    expect(@ai).to be_valid_image
    expect(@ai).to_not be_jp2able
    expect { @ai.create_jp2 }.to raise_error
  end

  it 'should run if you specify a bogus output profile, because this is not currently an option' do
    generate_test_image(TEST_TIF_INPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2(:output_profile=>'bogusness')
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_INPUT_FILE
    expect(TEST_JP2_INPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  it 'should not run if you specify a bogus tmp folder' do
    generate_test_image(TEST_TIF_INPUT_FILE)
    bogus_folder='/crapsticks'
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to_not exist bogus_folder
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    expect { @ai.create_jp2(:tmp_folder=>bogus_folder) }.to raise_error
  end

  it 'should create a jp2 and preserve the temporary file if specified' do
    generate_test_image(TEST_TIF_INPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE, :preserve_tmp_source=>true)
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
    expect(File.exists?(@ai.tmp_path)).to be true
  end

  it 'should create jp2 of the same filename and in the same location as the input if no output file is specified, and should cleanup tmp file' do
    generate_test_image(TEST_TIF_INPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File.exists?(TEST_JP2_INPUT_FILE)).to be false
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_INPUT_FILE
    expect(TEST_JP2_INPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
    expect(File.exists?(@ai.tmp_path)).to be false
  end

  it 'should create jp2 from input JPEG of the same filename and in the same location as the input if no output file is specified, and should cleanup tmp file' do
    generate_test_image(TEST_JPEG_INPUT_FILE)
    expect(File).to exist TEST_JPEG_INPUT_FILE
    expect(File).to_not exist TEST_JP2_INPUT_FILE
    @ai = Assembly::Image.new(TEST_JPEG_INPUT_FILE)
    result=@ai.create_jp2
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_INPUT_FILE
    expect(TEST_JP2_INPUT_FILE).to be_a_jp2
    expect(File.exists?(@ai.tmp_path)).to be false
  end

  it 'should recreate jp2 if the output file exists and if you allow overwriting' do
    generate_test_image(TEST_TIF_INPUT_FILE)
    generate_test_image(TEST_JP2_OUTPUT_FILE)
    expect(File).to exist TEST_TIF_INPUT_FILE
    expect(File).to exist TEST_JP2_OUTPUT_FILE
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE,:overwrite => true)
    expect(result).to be_a_kind_of Assembly::Image
    expect(result.path).to eq TEST_JP2_OUTPUT_FILE
    expect(TEST_JP2_OUTPUT_FILE).to be_a_jp2
    expect(result.exif.colorspace).to eq 'sRGB'
  end

  after(:each) do
    # after each test, empty out the input and output test directories
    remove_files(TEST_INPUT_DIR)
    remove_files(TEST_OUTPUT_DIR)
  end

end
