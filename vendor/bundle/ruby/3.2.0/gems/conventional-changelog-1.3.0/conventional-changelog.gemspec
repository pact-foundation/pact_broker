# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conventional_changelog/version'

Gem::Specification.new do |spec|
  spec.name          = "conventional-changelog"
  spec.version       = ConventionalChangelog::VERSION
  spec.authors       = ["Diego Carrion"]
  spec.email         = ["dc.rec1@gmail.com"]
  spec.summary       = %q{Ruby binary to generate a conventional changelog — Edit}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/dcrec1/conventional-changelog-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", ">= 3.2"
  spec.add_development_dependency "fakefs"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.1"
end
