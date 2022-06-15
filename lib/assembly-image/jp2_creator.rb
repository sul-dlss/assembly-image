# frozen_string_literal: true

require 'assembly-objectfile'
require 'tempfile'
require 'English' # see https://github.com/rubocop-hq/rubocop/issues/1747 (not #MAGA related)

module Assembly
  class Image < Assembly::ObjectFile
    # Creates jp2 derivatives
    class Jp2Creator # rubocop:disable  Metrics/ClassLength
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
        '-precise', # forces the use of 32-bit representations
        '-no_weights', # minimization of the MSE over all reconstructed colour components
        '-quiet', # suppress informative messages.
        'Creversible=no', # Disable reversible compression
        'Cmodes=BYPASS', #
        'Corder=RPCL', # R=resolution P=position C=component L=layer
        'Cblk=\\{64,64\\}', # code-block dimensions; 64x64 happens to also be the default
        'Cprecincts=\\{256,256\\},\\{256,256\\},\\{128,128\\}', # Precinct dimensions; 256x256 for the 2 highest resolution levels, defaults to 128x128 for the rest
        'ORGgen_plt=yes', # Insert packet length information
        '-rate 1.5', # Ratio of compressed bits to the image size
        'Clevels=5' # Number of wavelet decomposition levels, or stages
      ].freeze

      # rubocop:disable Metrics/AbcSize
      def create_jp2_checks
        image.send(:check_for_file)
        raise 'input file is not a valid image, or is the wrong mimetype' unless image.jp2able?

        raise SecurityError, "output #{output_path} exists, cannot overwrite" if !overwrite? && File.exist?(output_path)
        raise SecurityError, 'cannot recreate jp2 over itself' if overwrite? && image.mimetype == 'image/jp2' && output_path == image.path
      end

      # rubocop:disable Metrics/MethodLength
      def profile_conversion_switch(profile, tmp_folder:)
        path_to_profiles = File.join(Assembly::PATH_TO_IMAGE_GEM, 'profiles')
        # eventually we may allow the user to specify the output_profile...when we do, you can just uncomment this code
        # and update the tests that check for this
        output_profile = 'sRGBIEC6196621' # params[:output_profile] || 'sRGBIEC6196621'
        output_profile_file = File.join(path_to_profiles, "#{output_profile}.icc")

        raise "output profile #{output_profile} invalid" unless File.exist?(output_profile_file)

        return '' if image.profile.nil?

        # if the input color profile exists, contract paths to the profile and setup the command

        input_profile = profile.gsub(/[^[:alnum:]]/, '') # remove all non alpha-numeric characters, so we can get to a filename

        # construct a path to the input profile, which might exist either in the gem itself or in the tmp folder
        input_profile_file_gem = File.join(path_to_profiles, "#{input_profile}.icc")
        input_profile_file_tmp = File.join(tmp_folder, "#{input_profile}.icc")
        input_profile_file = File.exist?(input_profile_file_gem) ? input_profile_file_gem : input_profile_file_tmp

        # if input profile was extracted and does not matches an existing known profile either in the gem or in the tmp folder,
        # we'll issue an imagicmagick command to extract the profile to the tmp folder
        unless File.exist?(input_profile_file)
          input_profile_extract_command = "MAGICK_TEMPORARY_PATH=#{tmp_folder} convert '#{image.path}'[0] #{input_profile_file}" # extract profile from input image
          result = `#{input_profile_extract_command} 2>&1`
          raise "input profile extraction command failed: #{input_profile_extract_command} with result #{result}" unless $CHILD_STATUS.success?
          # if extraction failed or we cannot write the file, throw exception
          raise 'input profile is not a known profile and could not be extracted from input file' unless File.exist?(input_profile_file)
        end

        "-profile #{input_profile_file} -profile #{output_profile_file}"
      end

      # Bigtiff needs to be used if size of image exceeds 2^32 bytes.
      def need_bigtiff?
        image.image_data_size >= 2**32
      end

      # We do this because we need to reliably compress the tiff and KDUcompress doesn’t support arbitrary image types
      def make_tmp_tiff(tmp_folder: nil)
        tmp_folder ||= Dir.tmpdir
        raise "tmp_folder #{tmp_folder} does not exists" unless File.exist?(tmp_folder)

        # make temp tiff filename
        tmp_tiff_file = Tempfile.new(['assembly-image', '.tif'], tmp_folder)
        tmp_path = tmp_tiff_file.path

        options = []

        # Limit the amount of memory ImageMagick is able to use.
        options << '-limit memory 1GiB -limit map 1GiB'

        case image.samples_per_pixel
        when 3
          options << '-type TrueColor'
        when 1
          options << '-depth 8' # force the production of a grayscale access derivative
          options << '-type Grayscale'
        end

        options << profile_conversion_switch(image.profile, tmp_folder: tmp_folder)

        # The output in the covnert command needs to be prefixed by the image type. By default ImageMagick
        # will assume TIFF: when the file extension is .tif/.tiff. TIFF64: Needs to be forced when image will
        # exceed 2^32 bytes in size
        tiff_type = need_bigtiff? ? 'TIFF64:' : ''

        tiff_command = "MAGICK_TEMPORARY_PATH=#{tmp_folder} convert -quiet -compress none #{options.join(' ')} '#{image.path}[0]' #{tiff_type}'#{tmp_path}'"
        result = `#{tiff_command} 2>&1`
        raise "tiff convert command failed: #{tiff_command} with result #{result}" unless $CHILD_STATUS.success?

        tmp_path
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end
