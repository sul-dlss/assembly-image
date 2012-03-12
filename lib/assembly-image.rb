module Assembly
  
  # the path to the gem, used to access profiles stored with the gem
  PATH_TO_GEM = File.expand_path(File.dirname(__FILE__) + '/..')

  # if input image is not one of these mime types, an error will be raised
  ALLOWED_MIMETYPES=["image/jpeg","image/tiff"] 
  
end
