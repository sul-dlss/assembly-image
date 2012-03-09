require 'rubygems'
require 'logger'

environment  = ENV['ENVIRONMENT'] ||= 'development'
project_root = File.expand_path(File.dirname(__FILE__) + '/..')

# Load config for current environment.
$LOAD_PATH.unshift(project_root + '/lib')
ENV_FILE = project_root + "/config/environments/#{environment}.rb"
require ENV_FILE

require 'assembly'
