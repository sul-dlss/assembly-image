module Assembly
  
  # The Images class contains methods to operate on multiple images in batch.
  class Images

    # Pass in a source path and have exif color profile descriptions added to all images contained.
    # This is useful if your source TIFFs do not have color profile descriptions in the EXIF data, but you know what it should be.
    # This will allow the images to pass the validty check and have JP2s created successfully.
    #
    # Note you will need full read/write access to the source path so that new EXIF data can be saved.
    #
    # @param [String] source path full path to the directory containing TIFFs
    # @param [String] profile_name profile name to be added, current options are 'Adobe RBG 1998','Dot Gain 20%','sRGB IEC61966-2.1'
    #
    # @param [Hash] params Optional parameters specified as a hash, using symbols for options:
    #   * :force => if set to true, force overwrite a color profile description even if it already exists (default: false)
    #   * :recusrive => if set to true, directories will be searched recursively for TIFFs from the source specified, false searches the top level only (default: false)
    #   * :extension => defines the types of files that will be processed (default '.tif')
    #
    # Example:
    #  Assembly::Images.batch_add_exif_profile_description('/full_path_to_tifs','Adobe RGB 1998')    
    def self.batch_add_exif_profile_description(source,profile_name,params={})

      extension = params[:extension] || 'tif'
      recursive = params[:recursive] || false
      force = params[:force] || false
      
      raise "Input path does not exist" unless File.directory?(source)
      
      puts "Source: #{source}"

      # iterate over input directory looking for tifs
      pattern = recursive ? "**/*.#{extension}" : "*.#{extension}*" 
      Dir.glob(File.join(source,pattern)).each do |file|
        exif=MiniExiftool.new file
        begin
          if exif.profiledescription == nil || force
            input_profile = profile_name.gsub(/[^[:alnum:]]/, '')   # remove all non alpha-numeric characters, so we can get to a filename
            path_to_profiles    = File.join(Assembly::PATH_TO_IMAGE_GEM,'profiles')
            input_profile_file = File.join(path_to_profiles,"#{input_profile}.icc")
            command="exiftool '-icc_profile<=#{input_profile_file}' #{file}"
            result=`#{command}`
            raise "profile addition command failed: #{command} with result #{result}" unless $?.success?
          end
        rescue Exception => e
          puts "** Error for #{File.basename(file)}: #{e.message}"
        end
      end
      return 'Complete'
    end
    
    # Pass in a source path and get JP2s generate for each tiff that is in the source path
    #
    # If not passed in, the destination will be a "jp2" subfolder within the source folder.
    # Note you will need read access to the source path, and write access to the destination path.
    #
    # @param [String] source path full path to the directory containing TIFFs to be converted to JP2
    #
    # @param [Hash] params Optional parameters specified as a hash, using symbols for options:
    #   * :output=>'/full/path_to_jp2' # specifies full path to folder where jp2s will be created (default: jp2 subdirectory from source path)
    #   * :overwrite => if set to false, an existing JP2 file with the same name won't be overwritten (default: false)
    #   * :recursive => if set to true, directories will be searched recursively for TIFFs from the source specified, false searches the top level only (default: false)
    #   * :extension => defines the types of files that will be processed (default '.tif')
    #
    # Example:
    #  Assembly::Images.batch_generate_jp2('/full_path_to_tifs')
    def self.batch_generate_jp2(source,params={})
      
        raise "Input path does not exist" unless File.directory?(source)
        output = params[:output] || File.join(source,'jp2') # default output directgory is jp2 sub-directory from source
        extension = params[:extension] || 'tif'
        overwrite = params[:overwrite] || false
        recursive = params[:recursive] || false
                
        Dir.mkdir(output) unless File.directory?(output) # attemp to make output directory
        raise "Output path does not exist or could not be created" unless File.directory?(output) 

        puts "Source: #{source}"
        puts "Destination: #{output}"
  
        pattern = recursive ? "**/*.#{extension}" : "*.#{extension}*" 

        # iterate over input directory looking for tifs
        Dir.glob(File.join(source,pattern)).each do |file|
          source_img=Assembly::Image.new(file)
          output_img=File.join(output,File.basename(file,File.extname(file))+'.jp2') # output image gets same file name as source, but with a jp2 extension and in the correct output directory
          begin
            derivative_img=source_img.create_jp2(:overwrite=>overwrite,:output=>output_img)
            puts "Generated jp2 for #{File.basename(file)}"
          rescue Exception => e
            puts "** Error for #{File.basename(file)}: #{e.message}"
          end
        end
        return 'Complete'
        
    end
  end
end
