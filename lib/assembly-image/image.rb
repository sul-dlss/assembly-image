# frozen_string_literal: true

require 'vips'
require 'assembly-objectfile'
require_relative 'jp2_creator'

module Assembly
  # The Image class contains methods to operate on an image.
  class Image < Assembly::ObjectFile
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

    # Returns the full default jp2 path and filename that will be created from the given image
    #
    # @return [string] full default jp2 path and filename that will be created from the given image
    # Example:
    #   source_img=Assembly::Image.new('/input/path_to_file.tif')
    #   puts source_img.jp2_filename # gives /input/path_to_file.jp2
    def jp2_filename
      File.extname(path).empty? ? "#{path}.jp2" : path.gsub(File.extname(path), '.jp2')
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
