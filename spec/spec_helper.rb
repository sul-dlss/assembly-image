environment = ENV['ROBOT_ENVIRONMENT'] ||= 'development'

bootfile = File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require bootfile
require 'fileutils'
require 'mini_exiftool'


TEST_INPUT_DIR       = File.join(Assembly::PATH_TO_GEM,'spec','test_data','input')
TEST_OUTPUT_DIR      = File.join(Assembly::PATH_TO_GEM,'spec','test_data','output')
TEST_TIF_INPUT_FILE  = File.join(TEST_INPUT_DIR,'test.tif')
TEST_JP2_INPUT_FILE  = File.join(TEST_INPUT_DIR,'test.jp2')
TEST_JP2_OUTPUT_FILE = File.join(TEST_OUTPUT_DIR,'test.jp2')
TEST_DRUID           = "nx288wh8889"

# generate a sample image file
def generate_test_image(file)
  system("convert -size 100x100 xc:white #{file}")
end

def remove_files(dir)
  Dir.foreach(dir) {|f| fn = File.join(dir, f); File.delete(fn) if !File.directory?(fn) && File.basename(fn) != '.empty'}
end

# check the existence and mime_type of the supplied file and confirm if it's jp2
def is_jp2?(file)
  if File.exists?(file)
    exif = MiniExiftool.new file
    return exif['mimetype'] == 'image/jp2'
  else
    false
  end
end