module Assembly
  
  # the path to the gem, used to access profiles stored with the gem
  PATH_TO_IMAGE_GEM = File.expand_path(File.dirname(__FILE__) + '/..')
  
end

# auto-include all files in the lib sub-directory directory (except version, which was already included earlier)
Dir[File.dirname(__FILE__) + '/assembly-image/*.rb'].each {|file| require file unless file.include?('version.rb')}
