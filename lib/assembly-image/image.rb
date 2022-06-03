# frozen_string_literal: true

require 'assembly-objectfile'
require_relative 'jp2_creator'

module Assembly
  # The Image class contains methods to operate on an image.
  class Image
    # include common behaviors from assembly-objectfile gem
    include Assembly::ObjectFileable

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
        path_to_profiles = File.join(Assembly::PATH_TO_IMAGE_GEM, 'profiles')
        input_profile_file = File.join(path_to_profiles, "#{input_profile}.icc")
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
      File.extname(path).empty? ? "#{path}.jp2" : path.gsub(File.extname(path), '.jp2')
    end

    # Returns the full DPG equivalent jp2 path and filename that would match with the given image
    #
    # @return [string] full DPG equivalent jp2 path and filename
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.jp2_filename # gives /input/path_to_file.jp2
    def dpg_jp2_filename
      jp2_filename.gsub('_00_', '_05_')
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
      Jp2Creator.create(self, params)
    end

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

    # Get size of image data in bytes
    def image_data_size
      (samples_per_pixel * height * width * bits_per_sample) / 8
    end

    private

    # rubocop:enable Metrics/CyclomaticComplexity
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
  end
end
