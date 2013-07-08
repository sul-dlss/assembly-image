$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'assembly-image/version'

Gem::Specification.new do |s|
  s.name        = 'assembly-image'
  s.version     = Assembly::Image::VERSION
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
  s.add_dependency 'assembly-objectfile', ">= 1.4.1"
  s.add_dependency 'mini_exiftool', "~> 1.6"
  s.add_dependency 'activesupport', ((RUBY_VERSION < '1.9.3') ? "~> 3" : "") # 4.0 requires ruby 1.9.3
  s.add_dependency 'nokogiri', ((RUBY_VERSION < '1.9') ? "~> 1.5.10" : "~> 1") # 1.6.x requires ruby 1.9

  s.add_development_dependency "rspec", "~> 2.6"
  s.add_development_dependency "lyberteam-devel", '>= 1.0.1'
  s.add_development_dependency "lyberteam-gems-devel", "> 1.0.0"
  s.add_development_dependency "yard"
  
end