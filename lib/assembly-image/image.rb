require 'uuidtools'
require 'assembly-objectfile'

module Assembly
  
  # The Image class contains methods to operate on an image.
  class Image

    # include common behaviors from assembly-objectfile gem
    include Assembly::ObjectFileable

    # stores the path to the tmp file generated during the JP2 creation process
    attr_accessor :tmp_path

    # Examines the input image for validity.  Used to determine if image is correct and if JP2 generation is likely to succeed.
    #  This method is automatically called before you create a jp2 but it can be called separately earlier as a sanity check.
    #
    # @return [boolean] true if image is valid, false if not.
    #
    # Example:
    #   source_img=Assembly::ObjectFile.new('/input/path_to_file.tif')
    #   puts source_img.valid? # gives true
    def valid?
      valid_image? # behavior is defined in assembly-objectfile gem
    end
    
    # Get the image height from exif data
    #
    # @return [integer] image height in pixels
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.height # gives 100
    def height
      exif.imageheight
    end

    # Get the image width from exif data
    #
    # @return [integer] image height in pixels
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.width # gives 100    
    def width
      exif.imagewidth
    end
    
    # Returns the full default jp2 path and filename that will be created from the given image
    #
    # @return [string] full default jp2 path and filename that will be created from the given image
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.jp2_filename # gives /input/path_to_file.jp2
    def jp2_filename
      @path.gsub(File.extname(@path),'.jp2')
    end

    # Returns the full DPG equivalent jp2 path and filename that would match with the given image
    #
    # @return [string] full DPG equivalent jp2 path and filename
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.jp2_filename # gives /input/path_to_file.jp2
    def dpg_jp2_filename
      @path.gsub(File.extname(@path),'.jp2').gsub('_00_','_05_')
    end
        
    # Create a JP2 file for the current image.
    # Important note: this will not work for multipage TIFFs.
    #
    # @return [Assembly::Image] object containing the generated JP2 file
    #
    # @param [Hash] params Optional parameters specified as a hash, using symbols for options:
    #   * :output => path to the output JP2 file (default: mirrors the source file name and path, but with a .jp2 extension)
    #   * :overwrite => if set to false, an existing JP2 file with the same name won't be overwritten (default: false)
    #   * :tmp_folder =>  the temporary folder to use when creating the jp2 (default: '/tmp')
    #   * :preserve_tmp_source => if set to true, preserve the temporary file generated during the creation process and store path in 'tmp_path' attribute (default: false)
    #
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   derivative_img=source_img.create_jp2(:overwrite=>true)
    #   puts derivative_img.mimetype # 'image/jp2'
    #   puts derivative_image.path # '/input/path_to_file.jp2'
    def create_jp2(params = {})

      check_for_file

      raise "input file is not a valid image, is the wrong mimetype or is missing a profile" if !self.jp2able?
      
      output    = params[:output] || jp2_filename
      overwrite = params[:overwrite] || false

      raise SecurityError,"output #{output} exists, cannot overwrite" if !overwrite && File.exists?(output)

      raise SecurityError,"cannot recreate jp2 over itself" if overwrite && mimetype=='image/jp2' && output == @path

      tmp_folder = params[:tmp_folder] || '/tmp'
      raise "tmp_folder #{tmp_folder} does not exists" unless File.exists?(tmp_folder)
      
      output_profile      = 'sRGBIEC6196621' # params[:output_profile] || 'sRGBIEC6196621'  # eventually we may allow the user to specify the output_profile...when we do, you can just uncomment this code and update the tests that check for this
      preserve_tmp_source = params[:preserve_tmp_source] || false
      path_to_profiles    = File.join(Assembly::PATH_TO_IMAGE_GEM,'profiles')
      output_profile_file = File.join(path_to_profiles,"#{output_profile}.icc")

      raise "output profile #{output_profile} invalid" if !File.exists?(output_profile_file)

      path_to_profiles   = File.join(Assembly::PATH_TO_IMAGE_GEM,'profiles')
    
      input_profile = exif['profiledescription'].gsub(/[^[:alnum:]]/, '')   # remove all non alpha-numeric characters, so we can get to a filename
      
      # construct a path to the input profile, which might exist either in the gem itself or in the tmp folder
      input_profile_file_gem = File.join(path_to_profiles,"#{input_profile}.icc")
      input_profile_file_tmp = File.join(tmp_folder,"#{input_profile}.icc")
      input_profile_file = File.exists?(input_profile_file_gem) ? input_profile_file_gem : input_profile_file_tmp
       
      # if input profile was extracted and does not matches an existing known profile either in the gem or in the tmp folder,
      # we'll issue an imagicmagick command to extract the profile to the tmp folder
      unless File.exists?(input_profile_file)
        input_profile_extraction_command = "convert '#{@path}'[0] #{input_profile_file}" # extract profile from input image
        result=`#{input_profile_extraction_command}`
        raise "input profile extraction command failed: #{input_profile_extraction_command} with result #{result}" unless $?.success?
        raise "input profile is not a known profile and could not be extracted from input file" unless File.exists?(input_profile_file) # if extraction failed or we cannot write the file, throw exception
      end

      profile_conversion_switch = "-profile #{input_profile_file} -profile #{output_profile_file}"

      # make temp tiff
      @tmp_path      = "#{tmp_folder}/#{UUIDTools::UUID.random_create.to_s}.tif"
      
      tiff_command       = "convert -quiet -compress none #{profile_conversion_switch} '#{@path}' '#{@tmp_path}'"
      result=`#{tiff_command}`
      raise "tiff convert command failed: #{tiff_command} with result #{result}" unless $?.success?

      pixdem = width > height ? width : height
      layers = (( Math.log(pixdem) / Math.log(2) ) - ( Math.log(96) / Math.log(2) )).ceil + 1

      samples_per_pixel=exif['samplesperpixel'] || ""
      
      # jp2 creation command
      kdu_bin     = "kdu_compress "
      options     = ""
      options +=  " -jp2_space sRGB " if samples_per_pixel.to_s == "3"
      options     = " -precise -no_weights -quiet Creversible=no Cmodes=BYPASS Corder=RPCL " + 
                    "Cblk=\\{64,64\\} Cprecincts=\\{256,256\\},\\{256,256\\},\\{128,128\\} " + 
                    "ORGgen_plt=yes -rate 1.5 Clevels=5 "
      jp2_command = "#{kdu_bin} #{options} Clayers=#{layers.to_s} -i '#{@tmp_path}' -o '#{output}'"
      result=`#{jp2_command}`
      raise "JP2 creation command failed: #{jp2_command} with result #{result}" unless $?.success?
      
      File.delete(@tmp_path) unless preserve_tmp_source

      # create output response object, which is an Assembly::Image type object
      return Assembly::Image.new(output)
      
    end

  end
  
end
