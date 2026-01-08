# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name        = 'assembly-image'
  s.version     = '2.1.3'
  s.authors     = ['Peter Mangiafico', 'Renzo Sanchez-Silva', 'Monty Hindman', 'Tony Calavano']
  s.email       = ['pmangiafico@stanford.edu']
  s.homepage    = ''
  s.summary     = 'Ruby implementation of image services needed to prepare objects to be accessioned in SULAIR digital library'
  s.description = 'Contains classes to create derivative image files and perform other image operations'
  s.metadata['rubygems_mfa_required'] = 'true'

  s.files         = `git ls-files`.split("\n")
  s.bindir        = 'exe'
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'activesupport', '> 6.1'
  s.add_dependency 'assembly-objectfile', '>= 1.6.4'
  s.add_dependency 'ruby-vips', '>= 2.0'

  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-capybara'
  s.add_development_dependency 'rubocop-factory_bot'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'rubocop-rspec_rails'
  s.add_development_dependency 'simplecov'
end
