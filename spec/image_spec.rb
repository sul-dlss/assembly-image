describe Assembly::Image do

  it "should not run if no input file is passed in" do
    @ai=Assembly::Image.new('')
    lambda{@ai.create_jp2}.should raise_error
  end
  
  it "should indicate the default jp2 filename" do
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    @ai.jp2_filename.should == TEST_TIF_INPUT_FILE.gsub('.tif','.jp2')
  end

  it "should indicate the default DPG jp2 filename" do
    @ai = Assembly::Image.new(TEST_DPG_TIF_INPUT_FILE)
    @ai.dpg_jp2_filename.should == TEST_DPG_TIF_INPUT_FILE.gsub('.tif','.jp2').gsub('_00_','_05_')
  end

  it "should create jp2 when given an RGB tif" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    File.exists?(TEST_JP2_OUTPUT_FILE).should be false
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    result.class.should be Assembly::Image
    result.path.should == TEST_JP2_OUTPUT_FILE        
    is_jp2?(TEST_JP2_OUTPUT_FILE).should be true
    result.exif.colorspace.should == "sRGB"
    @jp2=Assembly::Image.new(TEST_JP2_OUTPUT_FILE)
    @jp2.height.should == 100
    @jp2.width.should == 100
  end

  it "should create jp2 when given a greyscale tif" do
    generate_test_image(TEST_TIF_INPUT_FILE,:color=>'gray',:profile=>'AdobeRGB1998')
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    File.exists?(TEST_JP2_OUTPUT_FILE).should be false
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    @ai.has_color_profile?.should be true
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    result.class.should be Assembly::Image
    result.path.should == TEST_JP2_OUTPUT_FILE        
    is_jp2?(TEST_JP2_OUTPUT_FILE).should be true
    @ai.has_color_profile?.should be true
    result.jp2able?.should be false
    result.exif.colorspace.should == "sRGB"
  end

  it "should create grayscale jp2 when given a bitonal tif" do
    generate_test_image(TEST_TIF_INPUT_FILE,:color=>'white')
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    File.exists?(TEST_JP2_OUTPUT_FILE).should be false
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    @ai.has_color_profile?.should be true
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    is_jp2?(TEST_JP2_OUTPUT_FILE).should be true
    result.exif.colorspace.should == "Grayscale"    
  end

  it "should create a jp2 when the source image has no profile" do
    generate_test_image(TEST_TIF_INPUT_FILE,:profile=>'') # generate a test input with no profile
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    File.exists?(TEST_JP2_OUTPUT_FILE).should be false
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    @ai.has_color_profile?.should be false
    @ai.valid_image?.should be true
    @ai.jp2able?.should be true
    @ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)
    is_jp2?(TEST_JP2_OUTPUT_FILE).should be true
  end

  it "should not run if the output file exists and you don't allow overwriting" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    generate_test_image(TEST_JP2_OUTPUT_FILE)
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    File.exists?(TEST_JP2_OUTPUT_FILE).should be true
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    lambda{@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE)}.should raise_error(SecurityError)
  end

  it "should get the correct image height and width" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    @ai.height.should == 100
    @ai.width.should == 100    
  end
  
  it "should not run if the input file is a jp2" do
    generate_test_image(TEST_JP2_OUTPUT_FILE)
    File.exists?(TEST_JP2_OUTPUT_FILE).should be true
    @ai = Assembly::Image.new(TEST_JP2_OUTPUT_FILE)
    @ai.valid_image?.should be true
    @ai.jp2able?.should be false
    lambda{@ai.create_jp2}.should raise_error
  end

  it "should run if you specify a bogus output profile, because this is not currently an option" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2(:output_profile=>'bogusness')
    result.class.should be Assembly::Image
    result.path.should == TEST_JP2_INPUT_FILE    
    is_jp2?(TEST_JP2_INPUT_FILE).should be true  
    result.exif.colorspace.should == "sRGB"     
  end

  it "should not run if you specify a bogus tmp folder" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    bogus_folder='/crapsticks'
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    File.exists?(bogus_folder).should be false
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    lambda{@ai.create_jp2(:tmp_folder=>bogus_folder)}.should raise_error
  end

  it "should create a jp2 and preserve the temporary file if specified" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE, :preserve_tmp_source=>true)
    result.class.should be Assembly::Image
    result.path.should == TEST_JP2_OUTPUT_FILE    
    is_jp2?(TEST_JP2_OUTPUT_FILE).should be true
    result.exif.colorspace.should == "sRGB"    
    File.exists?(@ai.tmp_path).should be true
  end

  it "should create jp2 of the same filename and in the same location as the input if no output file is specified, and should cleanup tmp file" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    File.exists?(TEST_JP2_INPUT_FILE).should be false
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2
    result.class.should be Assembly::Image
    result.path.should == TEST_JP2_INPUT_FILE
    is_jp2?(TEST_JP2_INPUT_FILE).should be true
    result.exif.colorspace.should == "sRGB"
    File.exists?(@ai.tmp_path).should be false    
  end

  it "should create jp2 from input JPEG of the same filename and in the same location as the input if no output file is specified, and should cleanup tmp file" do
    generate_test_image(TEST_JPEG_INPUT_FILE)
    File.exists?(TEST_JPEG_INPUT_FILE).should be true
    File.exists?(TEST_JP2_INPUT_FILE).should be false
    @ai = Assembly::Image.new(TEST_JPEG_INPUT_FILE)
    result=@ai.create_jp2
    result.class.should be Assembly::Image
    result.path.should == TEST_JP2_INPUT_FILE
    is_jp2?(TEST_JP2_INPUT_FILE).should be true
    result.exif.colorspace.should == "sRGB"    
    File.exists?(@ai.tmp_path).should be false    
  end

  it "should recreate jp2 if the output file exists and if you allow overwriting" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    generate_test_image(TEST_JP2_OUTPUT_FILE)
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    File.exists?(TEST_JP2_OUTPUT_FILE).should be true
    @ai = Assembly::Image.new(TEST_TIF_INPUT_FILE)
    result=@ai.create_jp2(:output => TEST_JP2_OUTPUT_FILE,:overwrite => true)
    result.class.should be Assembly::Image
    result.path.should == TEST_JP2_OUTPUT_FILE 
    is_jp2?(TEST_JP2_OUTPUT_FILE).should be true
    result.exif.colorspace.should == "sRGB"           
  end

  after(:each) do
    # after each test, empty out the input and output test directories
    remove_files(TEST_INPUT_DIR)
    remove_files(TEST_OUTPUT_DIR)
  end

end
