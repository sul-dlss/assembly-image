# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'assembly-image/version'

Gem::Specification.new do |s|
  s.name        = 'assembly-image'
  s.version     = Assembly::Image::VERSION
  s.authors     = ['Peter Mangiafico', 'Renzo Sanchez-Silva', 'Monty Hindman', 'Tony Calavano']
  s.email       = ['pmangiafico@stanford.edu']
  s.homepage    = ''
  s.summary     = 'Ruby immplementation of image services needed to prepare objects to be accessioned in SULAIR digital library'
  s.description = 'Contains classes to create derivative image files and perform other image operations'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.bindir        = 'exe'
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'assembly-objectfile', '>= 1.6.4'
  s.add_dependency 'mini_exiftool', '>= 1.6', '< 3'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov', '~> 0.17.0' # CodeClimate cannot use SimpleCov >= 0.18.0 for generating test coverage
  s.add_development_dependency 'yard'
end
