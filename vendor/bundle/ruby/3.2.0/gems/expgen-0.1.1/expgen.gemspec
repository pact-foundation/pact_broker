# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'expgen/version'

Gem::Specification.new do |gem|
  gem.name          = "expgen"
  gem.version       = Expgen::VERSION
  gem.authors       = ["Jonas Nicklas"]
  gem.email         = ["jonas.nicklas@gmail.com"]
  gem.description   = %q{Generate random strings from regular expression}
  gem.summary       = %q{Generate random regular expression}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "parslet"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rspec"
end
