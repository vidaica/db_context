# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'db_context/version'

Gem::Specification.new do |spec|

  spec.name          = "db_context"
  spec.version       = DbContext::VERSION
  spec.authors       = ["Vi Dang"]
  spec.email         = ["dangquocvi@gmail.com"]
  spec.description   = "Help you easier to create db context"
  spec.summary       = "Help you easier to create db context"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", ">= 3.2.13"
  spec.add_runtime_dependency "factory_girl", ">= 3.2.0"
  spec.add_runtime_dependency "activerecord-import", ">= 0.3.1"
  
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"  
  spec.add_development_dependency "mysql2", "0.3.11"
  spec.add_development_dependency "standalone_migrations", "2.0.4"
  spec.add_development_dependency "rails", "3.2.13"
  spec.add_development_dependency "rspec", "2.9.0"  
  spec.add_development_dependency "database_cleaner", "0.9.1"
    
end
