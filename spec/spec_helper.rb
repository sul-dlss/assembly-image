# frozen_string_literal: true

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

# generate a sample image file with a specified profile
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
def generate_test_image(file, params = {})
  color = params[:color] || 'red'
  profile = params[:profile] || 'sRGBIEC6196621'
  image_type = params[:image_type]
  create_command = "convert -size 100x100 xc:#{color} "
  create_command += ' -profile ' + File.join(Assembly::PATH_TO_IMAGE_GEM, 'profiles', profile + '.icc') + ' ' unless profile == ''
  create_command += " -type #{image_type} " if image_type
  create_command += ' -compress lzw ' if params[:compress]
  create_command += file
  create_command += ' 2>&1'
  output = `#{ create_command }`
  raise "Failed to create test image #{file} (#{params}): \n#{output}" unless $CHILD_STATUS.success?
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength

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
