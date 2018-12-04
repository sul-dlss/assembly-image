# frozen_string_literal: true

require 'logger'
module Assembly
  # The Images class contains methods to operate on multiple images in batch.
  class Images
    def self.logger
      @logger ||= Logger.new(STDERR)
    end

    class << self
      attr_writer :logger
    end

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
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def self.batch_add_exif_profile_descr(source, profile_name, params = {})
      extension = params[:extension] || 'tif'
      recursive = params[:recursive] || false
      force = params[:force] || false

      raise 'Input path does not exist' unless File.directory?(source)

      logger.debug "Source: #{source}"

      # iterate over input directory looking for tifs
      pattern = recursive ? "**/*.#{extension}" : "*.#{extension}*"
      Dir.glob(File.join(source, pattern)).each do |file|
        img = Assembly::Image.new(file)
        logger.debug "Processing #{file}"
        img.add_exif_profile_description(profile_name, force)
      end
      'Complete'
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

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
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.batch_generate_jp2(source, params = {})
      raise 'Input path does not exist' unless File.directory?(source)

      output = params[:output] || File.join(source, 'jp2') # default output directgory is jp2 sub-directory from source
      extension = params[:extension] || 'tif'
      overwrite = params[:overwrite] || false
      recursive = params[:recursive] || false

      Dir.mkdir(output) unless File.directory?(output) # attemp to make output directory
      raise 'Output path does not exist or could not be created' unless File.directory?(output)

      logger.debug "Source: #{source}"
      logger.debug "Destination: #{output}"

      pattern = recursive ? "**/*.#{extension}" : "*.#{extension}*"

      # iterate over input directory looking for tifs
      Dir.glob(File.join(source, pattern)).each do |file|
        source_img = Assembly::Image.new(file)
        output_img = File.join(output, File.basename(file, File.extname(file)) + '.jp2') # output image gets same file name as source, but with a jp2 extension and in the correct output directory
        begin
          source_img.create_jp2(overwrite: overwrite, output: output_img)
          logger.debug "Generated jp2 for #{File.basename(file)}"
        rescue StandardError => e
          logger.debug "** Error for #{File.basename(file)}: #{e.message}"
        end
      end
      'Complete'
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
