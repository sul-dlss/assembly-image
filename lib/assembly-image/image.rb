# frozen_string_literal: true

require 'ruby-vips'
require 'assembly-objectfile'
require 'tempfile'
require 'English' # see https://github.com/rubocop-hq/rubocop/issues/1747 (not #MAGA related)

module Assembly
  # The Image class contains methods to operate on an image.
  # rubocop:disable Metrics/ClassLength
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

    # Get the image color profile
    #
    # @return [string] image color profile
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.profile # gives 'Adobe RGB 1998'
    def profile
      exif.nil? ? nil : exif['profiledescription']
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
    # @return [integer] image height in pixels
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.width # gives 100
    def width
      exif.imagewidth
    end

    # Examines the input image to determine if it is compressed.
    #
    # @return [boolean] true if image is compressed, false if not.
    #
    # Example:
    #   source_img=Assembly::ObjectFile.new('/input/path_to_file.tif')
    #   puts source_img.compressed? # gives true
    # def compressed?
    #   exif.compression != 'Uncompressed'
    # end

    # Add an exif color profile descriptions to the image.
    # This is useful if your source TIFFs do not have color profile descriptions in the EXIF data, but you know what it should be.
    # This will allow the images to pass the validaty check and have JP2s created successfully.
    #
    # Note you will need full read/write access to the source path so that new EXIF data can be saved.
    #
    # @param [String] profile_name profile name to be added, current options are 'Adobe RBG 1998','Dot Gain 20%','sRGB IEC61966-2.1'
    #
    # @param [String] force if set to true, force overwrite a color profile description even if it already exists (default: false)
    #
    # Example:
    #  source_img=Assembly::Image.new('/input/path_to_file.tif')
    #  source_img.add_exif_profile_description('Adobe RGB 1998')
    def add_exif_profile_description(profile_name, force = false)
      if profile.nil? || force
        input_profile = profile_name.gsub(/[^[:alnum:]]/, '') # remove all non alpha-numeric characters, so we can get to a filename
        input_profile_file = File.join(PATH_TO_PROFILES, "#{input_profile}.icc")
        command = "exiftool '-icc_profile<=#{input_profile_file}' #{path}"
        result = `#{command} 2>&1`
        raise "profile addition command failed: #{command} with result #{result}" unless $CHILD_STATUS.success?
      end
    rescue StandardError => e
      puts "** Error for #{filename}: #{e.message}"
    end

    # Returns the full default jp2 path and filename that will be created from the given image
    #
    # @return [string] full default jp2 path and filename that will be created from the given image
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.jp2_filename # gives /input/path_to_file.jp2
    def jp2_filename
      File.extname(@path).empty? ? "#{@path}.jp2" : @path.gsub(File.extname(@path), '.jp2')
    end

    # Create a JP2 file for the current image.
    # Important note: this will not work for multipage TIFFs.
    #
    # @return [Assembly::Image] object containing the generated JP2 file
    #
    # @param [Hash] params Optional parameters specified as a hash, using symbols for options:
    #   * :output => path to the output JP2 file (default: mirrors the source file name and path, but with a .jp2 extension)
    #   * :overwrite => if set to false, an existing JP2 file with the same name won't be overwritten (default: false)
    #   * :tmp_folder =>  the temporary folder to use when creating the jp2 (default: '/tmp'); also used by imagemagick
    #   * :preserve_tmp_source => if set to true, preserve the temporary file generated during the creation process and store path in 'tmp_path' attribute (default: false)
    #
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   derivative_img=source_img.create_jp2(:overwrite=>true)
    #   puts derivative_img.mimetype # 'image/jp2'
    #   puts derivative_image.path # '/input/path_to_file.jp2'
    # rubocop:disable Metrics/CyclomaticComplexity:
    def create_jp2(params = {})
      output = params[:output] || jp2_filename
      create_jp2_checks(output: output, overwrite: params[:overwrite])

      # Using instance variable so that can check in tests.
      @tmp_path = make_tmp_tiff(tmp_folder: params[:tmp_folder])

      jp2_command = jp2_create_command(source_path: @tmp_path, output: output)
      result = `#{jp2_command}`
      raise "JP2 creation command failed: #{jp2_command} with result #{result}" unless $CHILD_STATUS.success?

      File.delete(@tmp_path) unless @tmp_path.nil? || params[:preserve_tmp_source]

      # create output response object, which is an Assembly::Image type object
      Assembly::Image.new(output)
    end

    private

    def create_jp2_checks(output:, overwrite:)
      check_for_file
      raise 'input file is not a valid image, or is the wrong mimetype' unless jp2able?

      raise SecurityError, "output #{output} exists, cannot overwrite" if !overwrite && File.exist?(output)
      raise SecurityError, 'cannot recreate jp2 over itself' if overwrite && mimetype == 'image/jp2' && output == @path
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def jp2_create_command(source_path:, output:)
      kdu_bin = 'kdu_compress'
      options = []
      options << '-jp2_space sRGB' if samples_per_pixel == 3
      options += kdu_compress_default_options
      options << "Clayers=#{layers}"
      "#{kdu_bin} #{options.join(' ')} -i '#{source_path}' -o '#{output}' 2>&1"
    end

    # rubocop:disable Metrics/MethodLength
    def kdu_compress_default_options
      [
        '-num_threads 2', # forces Kakadu to only use 2 threads
        '-quiet', # suppress informative messages.
        'Creversible=no', # Disable reversible compression
        'Corder=RPCL', # R=resolution P=position C=component L=layer
        'Cblk=\\{64,64\\}', # code-block dimensions; 64x64 happens to also be the default
        'Cprecincts=\\{256,256\\},\\{256,256\\},\\{128,128\\}', # Precinct dimensions; 256x256 for the 2 highest resolution levels, defaults to 128x128 for the rest
        '-rate -', # Ratio of compressed bits to the image size
        'Clevels=5' # Number of wavelet decomposition levels, or stages
      ]
    end
    # rubocop:enable Metrics/MethodLength

    def samples_per_pixel
      if exif['samplesperpixel']
        exif['samplesperpixel'].to_i
      else
        case mimetype
        when 'image/tiff'
          1
        when 'image/jpeg'
          3
        end
      end
    end

    def bits_per_sample
      if exif['bitspersample']
        exif['bitspersample'].to_i
      else
        case mimetype
        when 'image/tiff'
          1
        end
      end
    end

    # Get size of image data in bytes
    def image_data_size
      (samples_per_pixel * height * width * bits_per_sample) / 8
    end

    # Bigtiff needs to be used if size of image exceeds 2^32 bytes.
    def need_bigtiff?
      image_data_size >= 2**32
    end

    # Get the number of JP2 layers to generate
    def layers
      pixdem = [width, height].max
      ((Math.log(pixdem) / Math.log(2)) - (Math.log(96) / Math.log(2))).ceil + 1
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def make_tmp_tiff(tmp_folder: nil)
      tmp_folder ||= Dir.tmpdir
      raise "tmp_folder #{tmp_folder} does not exists" unless File.exist?(tmp_folder)

      # make temp tiff filename
      tmp_tiff_file = Tempfile.new(['assembly-image', '.tif'], tmp_folder)
      @tmp_path = tmp_tiff_file.path
      vips_image = Vips::Image.new_from_file @path

      vips_image = if vips_image.interpretation.eql?(:cmyk)
                     vips_image.icc_transform(SRGB_ICC, input_profile: CMYK_ICC)
                   elsif !profile.nil?
                     vips_image.icc_transform(SRGB_ICC, embedded: true)
                   else
                     vips_image
                   end

      vips_image.tiffsave(@tmp_path, bigtiff: need_bigtiff?)
      @tmp_path
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
  end
  # rubocop:enable Metrics/ClassLength
end
