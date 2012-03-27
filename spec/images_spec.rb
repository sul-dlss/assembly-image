describe Assembly::Images do

  it "should not run if no input folder is passed in" do
    lambda{Assembly::Images.batch_generate_jp2('')}.should raise_error
  end

  it "should not run if a non-existent input folder is passed in" do
    lambda{Assembly::Images.batch_generate_jp2('/junk/path')}.should raise_error
  end

  it "should run and produe jp2s from input tiffs" do
    ['test1','test2','test3'].each {|image| generate_test_image(File.join(TEST_INPUT_DIR,"#{image}.tif")) }
    Assembly::Images.batch_generate_jp2(TEST_INPUT_DIR,:output=>TEST_OUTPUT_DIR)
    File.directory?(TEST_OUTPUT_DIR).should be true
    ['test1','test2','test3'].each {|image| is_jp2?(File.join(TEST_OUTPUT_DIR,"#{image}.jp2")).should be true }    
  end

  after(:each) do
    # after each test, empty out the input and output test directories
    remove_files(TEST_INPUT_DIR)
    remove_files(TEST_OUTPUT_DIR)
  end

end
