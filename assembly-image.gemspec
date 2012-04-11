$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'assembly-image/version'

Gem::Specification.new do |s|
  s.name        = 'assembly-image'
  s.version     = Assembly::VERSION
  s.authors     = ["Peter Mangiafico", "Renzo Sanchez-Silva","Monty Hindman","Tony Calavano"]
  s.email       = ["pmangiafico@stanford.edu"]
  s.homepage    = ""
  s.summary     = %q{Ruby immplementation of image services needed to prepare objects to be accessioned in SULAIR digital library}
  s.description = %q{Contains classes to create derivative image files and perform other image operations}

  s.rubyforge_project = 'assembly-image'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'uuidtools'
  s.add_dependency 'nokogiri'
  s.add_dependency 'assembly-objectfile', "~> 1.0.1"

  s.add_development_dependency "rspec", "~> 2.6"
  s.add_development_dependency "lyberteam-devel"
  s.add_development_dependency "yard"
  
end
