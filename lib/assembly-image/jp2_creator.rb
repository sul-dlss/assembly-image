# frozen_string_literal: true

require 'assembly-objectfile'
require 'tempfile'
require 'English' # see https://github.com/rubocop-hq/rubocop/issues/1747 (not #MAGA related)

module Assembly
  class Image < Assembly::ObjectFile
    # Creates jp2 derivatives
    class Jp2Creator
      # Create a JP2 file for the current image.
      # Important note: this will not work for multipage TIFFs.
      #
      # @return [Assembly::Image] object containing the generated JP2 file
      #
      # @param [Assembly::Image] the image file
      # @param [Hash] params Optional parameters specified as a hash, using symbols for options:
      #   * :output => path to the output JP2 file (default: mirrors the source file name and path, but with a .jp2 extension)
      #   * :overwrite => if set to false, an existing JP2 file with the same name won't be overwritten (default: false)
      #   * :tmp_folder =>  the temporary folder to use when creating the jp2 (default: '/tmp'); also used by imagemagick
      #
      # Example:
      #   source_img = Assembly::Image.new('/input/path_to_file.tif')
      #   derivative_img = source_img.create_jp2(:overwrite=>true)
      #   puts derivative_img.mimetype # 'image/jp2'
      #   puts derivative_image.path # '/input/path_to_file.jp2'
      def self.create(image, params = {})
        new(image, params).create
      end

      def initialize(image, params)
        @image = image
        @output_path = params.fetch(:output, image.jp2_filename)
        @tmp_folder = params[:tmp_folder]
        @overwrite = params[:overwrite]
        @params = params
      end

      attr_reader :image, :output_path, :tmp_folder, :tmp_path

      # @return [Assembly::Image] object containing the generated JP2 file
      def create
        create_jp2_checks

        # Using instance variable so that can check in tests.
        # We do this because we need to reliably compress the tiff and KDUcompress doesn’t support arbitrary image types
        @tmp_path = make_tmp_tiff(tmp_folder: tmp_folder)

        jp2_command = jp2_create_command(source_path: @tmp_path, output: output_path)
        result = `#{jp2_command}`
        unless $CHILD_STATUS.success?
          # Clean up any partial result
          File.delete(output_path) if File.exist?(output_path)
          raise "JP2 creation command failed: #{jp2_command} with result #{result}"
        end

        File.delete(@tmp_path) unless @tmp_path.nil?

        # create output response object, which is an Assembly::Image type object
        Image.new(output_path)
      end

      private

      def overwrite?
        @overwrite
      end

      def jp2_create_command(source_path:, output:)
        options = []
        # TODO: Consider using ruby-vips to determine the colorspace instead of relying on exif (which is done below)
        options << '-jp2_space sRGB' if image.samples_per_pixel == 3
        options += KDU_COMPRESS_DEFAULT_OPTIONS
        options << "Clayers=#{layers}"
        "kdu_compress #{options.join(' ')} -i '#{source_path}' -o '#{output}' 2>&1"
      end

      # Get the number of JP2 layers to generate
      def layers
        pixdem = [image.width, image.height].max
        ((Math.log(pixdem) / Math.log(2)) - (Math.log(96) / Math.log(2))).ceil + 1
      end

      KDU_COMPRESS_DEFAULT_OPTIONS = [
        '-num_threads 2', # forces Kakadu to only use 2 threads
        '-quiet', # suppress informative messages.
        'Creversible=no', # Disable reversible compression
        'Corder=RPCL', # R=resolution P=position C=component L=layer
        'Cblk=\\{64,64\\}', # code-block dimensions; 64x64 happens to also be the default
        'Cprecincts=\\{256,256\\},\\{256,256\\},\\{128,128\\}', # Precinct dimensions; 256x256 for the 2 highest resolution levels, defaults to 128x128 for the rest
        '-rate -', # Ratio of compressed bits to the image size
        'Clevels=5' # Number of wavelet decomposition levels, or stages
      ].freeze

      def create_jp2_checks
        image.send(:check_for_file)
        raise 'input file is not a valid image, or is the wrong mimetype' unless image.jp2able?

        raise SecurityError, "output #{output_path} exists, cannot overwrite" if !overwrite? && File.exist?(output_path)
        raise SecurityError, 'cannot recreate jp2 over itself' if overwrite? && image.mimetype == 'image/jp2' && output_path == image.path
      end

      # We do this because we need to reliably compress the tiff and KDUcompress doesn’t support arbitrary image types
      # rubocop:disable Metrics/MethodLength
      def make_tmp_tiff(tmp_folder: nil)
        tmp_folder ||= Dir.tmpdir
        raise "tmp_folder #{tmp_folder} does not exists" unless File.exist?(tmp_folder)

        # make temp tiff filename
        tmp_tiff_file = Tempfile.new(['assembly-image', '.tif'], tmp_folder)
        tmp_path = tmp_tiff_file.path
        vips_image = Vips::Image.new_from_file image.path

        vips_image = if vips_image.interpretation.eql?(:cmyk)
                       vips_image.icc_transform(SRGB_ICC, input_profile: CMYK_ICC)
                     elsif !image.profile.nil?
                       vips_image.icc_transform(SRGB_ICC, embedded: true)
                     else
                       vips_image
                     end

        vips_image.tiffsave(tmp_path, bigtiff: true) # Use bigtiff so we can support images > 4GB
        tmp_path
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
