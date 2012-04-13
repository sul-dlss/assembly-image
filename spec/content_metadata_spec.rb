describe Assembly::ContentMetadata do

  it "should generate valid content metadata for a single tif and associated jp2" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    generate_test_image(TEST_JP2_INPUT_FILE)
    result = Assembly::ContentMetadata.create_content_metadata(TEST_DRUID,[[TEST_TIF_INPUT_FILE,TEST_JP2_INPUT_FILE]])
    result.class.should be String
    xml = Nokogiri::XML(result)
    xml.errors.size.should be 0
    xml.xpath("//resource").length.should be 1
    xml.xpath("//resource/file").length.should be 2
    xml.xpath("//label").length.should be 1
    xml.xpath("//label")[0].text.should =~ /Item \d+/
    xml.xpath("//resource/file")[0].attributes['size'].value.should == "63536"
    xml.xpath("//resource/file")[0].attributes['mimetype'].value.should == "image/tiff"
    xml.xpath("//resource/file")[0].attributes['publish'].value.should == "no"
    xml.xpath("//resource/file")[0].attributes['preserve'].value.should == "yes"
    xml.xpath("//resource/file")[0].attributes['shelve'].value.should == "no"
    xml.xpath("//resource/file/imageData")[0].attributes['width'].value.should == "100"
    xml.xpath("//resource/file/imageData")[0].attributes['height'].value.should == "100"
    xml.xpath("//resource/file")[1].attributes['size'].value.should == "306"
    xml.xpath("//resource/file")[1].attributes['mimetype'].value.should == "image/jp2"
    xml.xpath("//resource/file")[1].attributes['publish'].value.should == "yes"
    xml.xpath("//resource/file")[1].attributes['preserve'].value.should == "no"
    xml.xpath("//resource/file")[1].attributes['shelve'].value.should == "yes"
    xml.xpath("//resource/file/imageData")[1].attributes['width'].value.should == "100"
    xml.xpath("//resource/file/imageData")[1].attributes['height'].value.should == "100"    
  end

  it "should generate valid content metadata for two sets of tifs and associated jp2s" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    generate_test_image(TEST_JP2_INPUT_FILE)
    result = Assembly::ContentMetadata.create_content_metadata(TEST_DRUID,[[TEST_TIF_INPUT_FILE,TEST_JP2_INPUT_FILE],[TEST_TIF_INPUT_FILE,TEST_JP2_INPUT_FILE]])
    result.class.should be String
    xml = Nokogiri::XML(result)
    xml.errors.size.should be 0
    xml.xpath("//resource").length.should be 2
    xml.xpath("//resource/file").length.should be 4    
    xml.xpath("//label").length.should be 2
    xml.xpath("//label")[0].text.should =~ /Item \d+/
    xml.xpath("//label")[1].text.should =~ /Item \d+/
  end

  it "should not generate valid content metadata if not all input files exist" do
    generate_test_image(TEST_TIF_INPUT_FILE)
    File.exists?(TEST_TIF_INPUT_FILE).should be true
    File.exists?(TEST_JP2_INPUT_FILE).should be false
    result = Assembly::ContentMetadata.create_content_metadata(TEST_DRUID,[[TEST_TIF_INPUT_FILE,TEST_JP2_INPUT_FILE]],:content_label => "test label").should be false
  end

  after(:each) do
    # after each test, empty out the input and output test directories
    remove_files(TEST_INPUT_DIR)
    remove_files(TEST_OUTPUT_DIR)
  end

end
