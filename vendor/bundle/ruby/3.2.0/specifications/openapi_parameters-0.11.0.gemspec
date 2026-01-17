# -*- encoding: utf-8 -*-
# stub: openapi_parameters 0.11.0 ruby lib

Gem::Specification.new do |s|
  s.name = "openapi_parameters".freeze
  s.version = "0.11.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/ahx/openapi_parameters/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/ahx/openapi_parameters", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/ahx/openapi_parameters" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andreas Haller".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "This parses HTTP query/path/header/cookie parameters exactly as described in an OpenAPI API description.".freeze
  s.email = ["andreas.haller@posteo.de".freeze]
  s.homepage = "https://github.com/ahx/openapi_parameters".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "openapi_parameters is an OpenAPI aware parameter parser".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 2.2"])
end
