# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name        = 'assembly-image'
  s.version     = '1.8.0'
  s.authors     = ['Peter Mangiafico', 'Renzo Sanchez-Silva', 'Monty Hindman', 'Tony Calavano']
  s.email       = ['pmangiafico@stanford.edu']
  s.homepage    = ''
  s.summary     = 'Ruby immplementation of image services needed to prepare objects to be accessioned in SULAIR digital library'
  s.description = 'Contains classes to create derivative image files and perform other image operations'
  s.metadata['rubygems_mfa_required'] = 'true'

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
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard'
end
