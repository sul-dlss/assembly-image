# frozen_string_literal: true

require 'vips'
require 'assembly-objectfile'
require_relative 'image/jp2_creator'

module Assembly
  # The Image class contains methods to operate on an image.
  class Image < Assembly::ObjectFile
    # @return [integer] image height in pixels
    def height
      vips_image.height
    end

    # @return [integer] image width in pixels
    def width
      vips_image.width
    end

    # @return [string] full default jp2 path and filename that will be created from the given image
    # Example:  given original file of '/dir/path_to_file.tif', gives '/dir/path_to_file.jp2'
    def jp2_filename
      # path is a property on Assembly::ObjectFile
      File.extname(path).empty? ? "#{path}.jp2" : path.gsub(File.extname(path), '.jp2')
    end

    # Create a JP2 file for the current image.
    # Important note: this will not work for multipage TIFFs.
    #
    # @param [String] output path to the output JP2 file (default: mirrors the source file name and path, but with a .jp2 extension)
    # @param [Boolean] overwrite if set to false, an existing JP2 file with the same name won't be overwritten (default: false)
    # @param [Dir] tmp_folder the temporary folder to use when creating the jp2 (default: '/tmp'); also used by imagemagick
    # @return [Assembly::Image] object containing the generated JP2 file
    #
    # Example:
    #   source_img = Assembly::Image.new('/dir/path_to_file.tif')
    #   jp2_img = source_img.create_jp2(overwrite: true)
    #   jp2_img.mimetype # 'image/jp2'
    #   jp2_img.path # '/dir/path_to_file.jp2'
    def create_jp2(**params)
      Jp2Creator.create(self, **params)
    end

    def vips_image
      # autorot will only affect images that need rotation: https://www.libvips.org/API/current/libvips-conversion.html#vips-autorot
      @vips_image ||= Vips::Image.new_from_file(path).autorot
    end

    def srgb?
      vips_image.interpretation == :srgb
    end

    # Does the image include an ICC profile?
    def has_profile?
      vips_image.get_fields.include?('icc-profile-data')
    end
  end
end
