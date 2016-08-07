# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'db_context/version'

Gem::Specification.new do |spec|

  spec.name          = "db_context"
  spec.version       = DbContext::VERSION
  spec.authors       = ["Vi Dang", "Khanh Nguyen"]
  spec.email         = ["dangquocvi@gmail.com", "nguyenvietnamkhanh@gmail.com"]
  spec.description   = "Help you easier to create db context"
  spec.summary       = "Help you easier to create db context"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord"
  spec.add_runtime_dependency "factory_girl"
  spec.add_runtime_dependency "activerecord-import"
  
  spec.add_development_dependency "rails"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"  
  spec.add_development_dependency "mysql2"
  #spec.add_development_dependency "standalone_migrations", "2.0.4"  
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "database_cleaner"
    
end
