require 'rubygems'
require 'logger'

environment  = ENV['ENVIRONMENT'] ||= 'development'
project_root = File.expand_path(File.dirname(__FILE__) + '/..')

# Load config for current environment.
$LOAD_PATH.unshift(project_root + '/lib')

require 'assembly-image'
require 'assembly-image/image'
require 'assembly-image/version'
require 'assembly-image/content_metadata'
