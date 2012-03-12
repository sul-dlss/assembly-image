require 'uuidtools'
require 'mini_exiftool'

module Assembly

  class Image

    attr_accessor :path, :tmp_path

    # Inititalize image from given path
    #
    # Required parameters:
    #   * path = full path to source image
    #
    # Example:
    #   Assembly::Image.new('/input/path_to_file.tif')
    def initialize(path)
      @path = path
      raise 'input file does not exist' unless File.exists?(@path)
    end
      
    # Returns exif information
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.exif.mimetype # gives 'image/tiff'    
    def exif
      @exif ||= MiniExiftool.new @path  
    end
    
    # Create a JP2 file
    #
    # Reponse:
    #   * an Assembly::Image object containing the generated JP2 file
    #
    # Optional parameters:
    #   * output          = path to the output JP2 file (default: mirrors the source file name with a .jp2 extension)
    #   * overwrite = an existing JP2 file won't be overwritten unless this is true
    #   * output_profile  =  output color space profile: either sRGB (the default) or AdobeRGB1998    
    #   * tmp_folder  =  the temporary folder to use when creating the jp2, defaults to '/tmp'
    #   * preserve_tmp_source = preserve the temporary file generated during the creation process (in 'tmp_path' attribute) if set to true, defaults to false
    #
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   derivative_img=source_img.create_jp2 
    #   puts derivative_img.exif.mimetype # gives 'image/jp2'
    def create_jp2(params = {})

      raise 'input file is not an image' unless Assembly::ALLOWED_MIMETYPES.include?(exif.mimetype)
    
      output    = params[:output] || @path.gsub(File.extname(@path),'.jp2')
      overwrite = params[:overwrite] || false

      raise "output #{output} exists, cannot overwrite" if !overwrite && File.exists?(output)

      tmp_folder = params[:tmp_folder] || '/tmp'
      raise "tmp_folder #{tmp_folder} does not exists" unless File.exists?(tmp_folder)
      
      output_profile      = params[:output_profile] || 'sRGB'
      preserve_tmp_source = params[:preserve_tmp_source] || false
      path_to_profiles    = File.join(Assembly::PATH_TO_GEM,'profiles')
      output_profile_file = File.join(path_to_profiles,"#{output_profile}.icc")

      raise "output profile #{output_profile} invalid" if !File.exists?(output_profile_file)

      path_to_profiles   = File.join(Assembly::PATH_TO_GEM,'profiles')
      # remove all non alpha-numeric characters, so we can get to a filename
      input_profile      = exif['profiledescription'].nil? ? "" :
                           exif['profiledescription'].gsub(/[^[:alnum:]]/, '')
      input_profile_file = File.join(path_to_profiles,"#{input_profile}.icc")

      # make temp tiff
      @tmp_path      = "#{tmp_folder}/#{UUIDTools::UUID.random_create.to_s}.tif"
      
      profile_conversion = File.exists?(input_profile_file) ?
                           "-profile #{input_profile_file} -profile #{output_profile_file}" : ""
      tiff_command       = "convert -quiet -compress none #{profile_conversion} #{@path} #{@tmp_path}"
      system(tiff_command)

      pixdem = exif.imagewidth > exif.imageheight ? exif.imagewidth : exif.imageheight
      layers = (( Math.log(pixdem) / Math.log(2) ) - ( Math.log(96) / Math.log(2) )).ceil + 1

      # Start jp2 creation section
      kdu_bin     = "kdu_compress "
      options     = " -precise -no_weights -quiet Creversible=no Cmodes=BYPASS Corder=RPCL " + 
                    "Cblk=\\{64,64\\} Cprecincts=\\{256,256\\},\\{256,256\\},\\{128,128\\} " + 
                    "ORGgen_plt=yes -rate 1.5 Clevels=5 "
      jp2_command = "#{kdu_bin} #{options} Clayers=#{layers.to_s} -i #{@tmp_path} -o #{output}"
      system(jp2_command)

      File.delete(@tmp_path) unless preserve_tmp_source

      # create output response object, with is an Assembly::Image type object
      return Assembly::Image.new(output)
      
    end

  end
  
end
