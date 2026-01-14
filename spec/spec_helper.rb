# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'

  if ENV['CI']
    require 'simplecov_json_formatter'

    formatter SimpleCov::Formatter::JSONFormatter
  end
end

bootfile = File.expand_path("#{File.dirname(__FILE__)}/../config/boot")
require bootfile
require 'debug'

TEST_INPUT_DIR       = File.join(Assembly::PATH_TO_IMAGE_GEM, 'spec', 'test_data', 'input')
TEST_OUTPUT_DIR      = File.join(Assembly::PATH_TO_IMAGE_GEM, 'spec', 'test_data', 'output')
TEST_TIF_INPUT_FILE  = File.join(TEST_INPUT_DIR, 'test.tif')
TEST_JPEG_INPUT_FILE = File.join(TEST_INPUT_DIR, 'test.jpg')
TEST_MULTIPAGE_TIF_FILE = File.join(Assembly::PATH_TO_IMAGE_GEM, 'spec', 'test_data', 'shapes_multi_size.tif')

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

# rubocop:disable Metrics/MethodLength
# Color values for 30-patch ColorGauge color target.
def color_gauge_values(type = 'adobeRGB')
  # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  # rubocop:disable Layout/ExtraSpacing
  adobe_rgb = [
    [109,  83,  71],  [187, 146, 129], [101, 120, 151], [ 97, 108,  68], [130, 128, 172],
    [130, 187, 171],  [ 64, 134, 165], [241, 242, 237], [231, 232, 229], [216, 217, 215],
    [203, 204, 203],  [202, 125,  55], [172,  87, 147], [174, 176, 175], [148, 150, 149],
    [116, 119, 118],  [ 91,  91,  92], [ 78,  92, 165], [227, 198,  55], [ 68,  70,  69],
    [ 48,  48,  48],  [ 32,  32,  32], [ 23,  23,  23], [175,  85,  97], [157,  60,  61],
    [100, 148,  80],  [ 53,  67, 141], [213, 160,  56], [167, 187,  77], [ 86,  61, 100]
  ]

  srgb = [
    [118,  82,  69], [202, 147, 129], [ 92, 121, 154], [ 92, 109,  64], [132, 129, 175],
    [ 96, 188, 172], [  0, 135, 168], [241, 242, 237], [231, 232, 229], [217, 218, 216],
    [204, 205, 204], [225, 126,  46], [196,  86, 150], [175, 178, 177], [148, 151, 150],
    [116, 120, 119], [ 91,  91,  92], [ 70,  92, 169], [238, 199,  27], [ 65,  68,  67],
    [ 44,  44,  44], [ 26,  26,  26], [ 16,  16,  16], [200,  84,  97], [181,  57,  58],
    [ 68, 149,  74], [ 42,  65, 145], [231, 161,  41], [160, 188,  65], [ 94,  58, 101]
  ]

  cmyk = [
    [120, 154, 169,  84], [ 69, 110, 120,   5], [169, 125,  64,   8], [154, 105, 207,  64],
    [138, 125,  31,   0], [128,  26,  95,   0], [195,  95,  61,   3], [ 10,   5, 13,    0],
    [ 20,  13,  18,   0], [ 36,  26,  31,   0], [ 51,  38,  41,   0], [ 46, 143, 236,   8],
    [ 90, 202,  31,   0], [ 84,  64,  69,   0], [115,  90,  95,   0], [143, 115, 120,  28],
    [161, 141, 136,  69], [205, 182,   8,   0], [ 33,  46, 238,   0], [172, 151, 151, 110],
    [179, 164, 161, 156], [184, 169, 166, 189], [187, 172, 166, 205], [ 69, 197, 131,  20],
    [ 69, 220, 189,  51], [161,  59, 223,  15], [241, 223,  28,   5], [ 44,  95, 238,   3],
    [100,  31, 228,   0], [184, 210,  90,  56]
  ]
  # rubocop:enable Layout/SpaceInsideArrayLiteralBrackets
  # rubocop:enable Layout/ExtraSpacing
  case type
  when 'adobe_rgb'
    adobe_rgb
  when 'srgb'
    srgb
  when 'cmyk'
    cmyk
  else
    raise 'Unknown color_gauge_values type.'
  end
end
# rubocop:enable Metrics/MethodLength

# generate a sample image file with a specified profile
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity
def generate_test_image(file, params = {})
  # Set default size for sample test image.
  line_size = 1
  box_size = 6
  width = (box_size * 6) + (line_size * 7)
  height = (box_size * 5) + (line_size * 6)

  # Set parameters for image creation options.
  image_type  = params[:image_type] || File.extname(file)
  bands       = params[:bands] || 3
  color       = params[:color] || 'rgb'
  depth       = params[:depth] || 8
  cg_type     = params[:cg_type] || 'adobe_rgb'
  compression = params[:compression]
  profile     = params[:profile]

  temp_array = color_gauge_values(cg_type)
  temp_image = Vips::Image.black(width, height, bands: temp_array.first.size)
  5.times do |i|
    b = (box_size * i) + (line_size * (i + 1))
    # d = b + box_size - line_size
    6.times do |j|
      a = (box_size * j) + (line_size * (j + 1))
      # c = a + box_size - line_size
      colors = temp_array.shift
      temp_image = temp_image.draw_rect(colors, a, b, box_size, box_size, fill: true)
    end
  end

  temp_image = color.eql?('cmyk') ? temp_image.copy(interpretation: :cmyk) : temp_image.copy(interpretation: :srgb)

  temp_image = if color.eql?('grey') && bands == 3
                 mean = temp_image.bandmean
                 Vips::Image.bandjoin([mean, mean, mean])
               elsif color.eql?('grey') && bands == 1
                 temp_image.bandmean
               elsif color.eql?('bin') && bands == 3
                 mean = temp_image.bandmean < 128
                 Vips::Image.bandjoin([mean, mean, mean])
               elsif color.eql?('bin') && bands == 1
                 temp_image.bandmean < 128
               else
                 temp_image
               end

  options = {}
  unless profile.nil?
    profile_file = File.join(Assembly::PATH_TO_IMAGE_GEM, 'profiles', "#{profile}.icc")
    options.merge!(profile: profile_file)
  end

  case image_type
  when '.tiff', '.tif'
    options.merge!(compression: compression) unless compression.nil?
    options.merge!(squash: true) if depth.eql?(1)
    temp_image.tiffsave(file, **options)
  when '.jpeg', '.jpg'
    temp_image.jpegsave(file, **options)
  else
    raise "unknown type: #{image_type}"
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity

def cleanup
  remove_files(TEST_INPUT_DIR)
  remove_files(TEST_OUTPUT_DIR)
end

def remove_files(dir)
  Dir.foreach(dir) do |f|
    fn = File.join(dir, f)
    File.delete(fn) if !File.directory?(fn) && File.basename(fn) != '.empty'
  end
end
