
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "json_schemer/version"

Gem::Specification.new do |spec|
  spec.name          = "json_schemer"
  spec.version       = JSONSchemer::VERSION
  spec.authors       = ["David Harsha"]
  spec.email         = ["davishmcclurg@gmail.com"]

  spec.summary       = "JSON Schema validator. Supports drafts 4, 6, 7, 2019-09, 2020-12, OpenAPI 3.0, and OpenAPI 3.1."
  spec.homepage      = "https://github.com/davishmcclurg/json_schemer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|JSON-Schema-Test-Suite)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.7'

  spec.add_development_dependency "base64"
  spec.add_development_dependency "bundler", "~> 2.4.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "csv"
  spec.add_development_dependency "i18n"
  spec.add_development_dependency "i18n-debug"
  spec.add_development_dependency "openssl", "~> 3.3.2"

  spec.add_runtime_dependency "bigdecimal"
  spec.add_runtime_dependency "hana", "~> 1.3"
  spec.add_runtime_dependency "regexp_parser", "~> 2.0"
  spec.add_runtime_dependency "simpleidn", "~> 0.2"
end
