# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end

bootfile = File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require bootfile

TEST_INPUT_DIR       = File.join(Assembly::PATH_TO_IMAGE_GEM, 'spec', 'test_data', 'input')
TEST_OUTPUT_DIR      = File.join(Assembly::PATH_TO_IMAGE_GEM, 'spec', 'test_data', 'output')
TEST_TIF_INPUT_FILE  = File.join(TEST_INPUT_DIR, 'test.tif')
TEST_DPG_TIF_INPUT_FILE = File.join(TEST_INPUT_DIR, 'oo000oo0001_00_01.tif')
TEST_JPEG_INPUT_FILE = File.join(TEST_INPUT_DIR, 'test.jpg')
TEST_JP2_INPUT_FILE  = File.join(TEST_INPUT_DIR, 'test.jp2')
TEST_JP2_OUTPUT_FILE = File.join(TEST_OUTPUT_DIR, 'test.jp2')
TEST_DRUID           = 'nx288wh8889'

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = 'spec/examples.txt'

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  # config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
end

# generate a sample image file with a specified profile
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity
def generate_test_image(file, params = {})
  width = params[:width] || '100'
  height = params[:height] || '100'
  color = params[:color] || 'TrueColor'
  profile = params[:profile] || 'sRGBIEC6196621'
  image_type = params[:image_type]
  create_command = "convert rose: -scale #{width}x#{height}\! -type #{color} "
  create_command += ' -profile ' + File.join(Assembly::PATH_TO_IMAGE_GEM, 'profiles', profile + '.icc') + ' ' unless profile == ''
  create_command += " -type #{image_type} " if image_type
  create_command += ' -compress lzw ' if params[:compress]
  create_command += file
  create_command += ' 2>&1'
  output = `#{create_command}`
  raise "Failed to create test image #{file} (#{params}): \n#{output}" unless $CHILD_STATUS.success?
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity

def remove_files(dir)
  Dir.foreach(dir) do |f|
    fn = File.join(dir, f)
    File.delete(fn) if !File.directory?(fn) && File.basename(fn) != '.empty'
  end
end

RSpec::Matchers.define :be_a_jp2 do
  match do |actual|
    if File.exist?(actual)
      exif = MiniExiftool.new actual
      exif['mimetype'] == 'image/jp2'
    else
      false
    end
  end
end
