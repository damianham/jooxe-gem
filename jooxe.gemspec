# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jooxe/version'

Gem::Specification.new do |gem|
  gem.name          = "jooxe"
  gem.version       = Jooxe::VERSION
  gem.authors       = ["Damian Hamill"]
  gem.email         = ["damianham@gmail.com"]
  gem.description   = %q{Jooxe is the zero code web application framework}
  gem.summary       = %q{Jooxe is a web application framework that displays database objects automatically, say adios to boilerplate}
  gem.homepage      = "http://jooxe.org"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.required_ruby_version     = '>= 1.9.2'
  
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'sqlite3'
  gem.add_dependency 'tilt'
  gem.add_dependency 'erubis'
  gem.add_dependency 'sequel'
  gem.add_dependency 'rack'
  gem.add_dependency 'json'
  gem.add_dependency 'bundler'
  
end
