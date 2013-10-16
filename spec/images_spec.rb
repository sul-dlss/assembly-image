require 'spec_helper'

describe Assembly::Images do

  it "should not run if no input folder is passed in" do
    lambda{Assembly::Images.batch_generate_jp2('')}.should raise_error
  end

  it "should not run if a non-existent input folder is passed in" do
    lambda{Assembly::Images.batch_generate_jp2('/junk/path')}.should raise_error
  end

  it "should run and batch produe jp2s from input tiffs" do
    ['test1','test2','test3'].each {|image| generate_test_image(File.join(TEST_INPUT_DIR,"#{image}.tif")) }
    Assembly::Images.batch_generate_jp2(TEST_INPUT_DIR,:output=>TEST_OUTPUT_DIR)
    File.directory?(TEST_OUTPUT_DIR).should be true
    ['test1','test2','test3'].each {|image| is_jp2?(File.join(TEST_OUTPUT_DIR,"#{image}.jp2")).should be_true }
  end

  it "should run and batch add color profile descriptions input tiffs with no color profile descriptions" do
    ['test1','test2','test3'].each {|image| generate_test_image(File.join(TEST_INPUT_DIR,"#{image}.tif"),:profile=>'') }
    ['test1','test2','test3'].each {|image| Assembly::Image.new(File.join(TEST_INPUT_DIR,"#{image}.tif")).exif.profiledescription.should be nil}    
    Assembly::Images.batch_add_exif_profile_description(TEST_INPUT_DIR,'Adobe RGB 1998')
    ['test1','test2','test3'].each {|image| Assembly::Image.new(File.join(TEST_INPUT_DIR,"#{image}.tif")).exif.profiledescription.should == 'Adobe RGB (1998)'}    
  end
  
  it "should run and batch add color profile descriptions input tiffs, forcing over existing color profile descriptions" do
    ['test1','test2','test3'].each {|image| generate_test_image(File.join(TEST_INPUT_DIR,"#{image}.tif")) }
    ['test1','test2','test3'].each {|image| Assembly::Image.new(File.join(TEST_INPUT_DIR,"#{image}.tif")).exif.profiledescription.should == 'sRGB IEC61966-2.1'}    
    Assembly::Images.batch_add_exif_profile_description(TEST_INPUT_DIR,'Adobe RGB 1998',:force=>true) # force overwrite
    ['test1','test2','test3'].each {|image| Assembly::Image.new(File.join(TEST_INPUT_DIR,"#{image}.tif")).exif.profiledescription.should == 'Adobe RGB (1998)'}    
  end

  it "should run and batch add color profile descriptions input tiffs, not overwriting existing color profile descriptions" do
    ['test1','test2','test3'].each {|image| generate_test_image(File.join(TEST_INPUT_DIR,"#{image}.tif")) }
    ['test1','test2','test3'].each {|image| Assembly::Image.new(File.join(TEST_INPUT_DIR,"#{image}.tif")).exif.profiledescription.should == 'sRGB IEC61966-2.1'}    
    Assembly::Images.batch_add_exif_profile_description(TEST_INPUT_DIR,'Adobe RGB 1998') # do not force overwrite
    ['test1','test2','test3'].each {|image| Assembly::Image.new(File.join(TEST_INPUT_DIR,"#{image}.tif")).exif.profiledescription.should == 'sRGB IEC61966-2.1'}    
  end


  after(:each) do
    # after each test, empty out the input and output test directories
    remove_files(TEST_INPUT_DIR)
    remove_files(TEST_OUTPUT_DIR)
  end

end
