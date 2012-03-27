module Assembly
  
  # The Images class contains methods to operate on multiple images in batch.
  class Images
    
    # Pass in a source path and get JP2s generate for each tiff that is in the source path
    #
    # If not passed in, the destination will be a "jp2" subfolder within the source folder.
    # Note you will need read access to the source path, and write access to the destination path.
    #
    # @param [String] path full path to the directory containing TIFFs to be converted to JP2
    #
    # @param [Hash] params Optional parameters specified as a hash, using symbols for options:
    #   * :output=>'/full/path_to_jp2' # specifies full path to folder where jp2s will be created (default: jp2 subdirectory from source path)
    #   * :overwrite => if set to false, an existing JP2 file with the same name won't be overwritten (default: false)
    #  
    # Example:
    #  Assembly::Images.batch_generate_jp2('/full_path_to_tifs')
    def self.batch_generate_jp2(source,params={})
      
        raise "Input path does not exist" unless File.directory?(source)
        output = params[:output] || File.join(source,'jp2') # default output directgory is jp2 sub-directory from source
        overwrite = params[:overwrite] || false
        
        Dir.mkdir(output) unless File.directory?(output) # attemp to make output directory
        raise "Output path does not exist or could not be created" unless File.directory?(output) 

        puts "Source: #{source}"
        puts "Destination: #{output}"
  
        # iterate over input directory looking for tifs
        Dir.glob(File.join(source,"*.tif*")).each do |tiff_file|
          source_img=Assembly::Image.new(tiff_file)
          output_img=File.join(output,File.basename(tiff_file,File.extname(tiff_file))+'.jp2') # output image gets same file name as source, but with a jp2 extension and in the correct output directory
          begin
            derivative_img=source_img.create_jp2(:overwrite=>overwrite,:output=>output_img)
            puts "Generated jp2 for #{File.basename(tiff_file)}"
          rescue Exception => e
            puts "** Error for #{File.basename(tiff_file)}: #{e.message}"
          end
        end
        return 'Complete'
        
    end
  end
end
