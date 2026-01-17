# -*- encoding: utf-8 -*-
# stub: openapi_first 2.11.1 ruby lib

Gem::Specification.new do |s|
  s.name = "openapi_first".freeze
  s.version = "2.11.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/ahx/openapi_first/blob/main/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/openapi_first/", "homepage_uri" => "https://github.com/ahx/openapi_first", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/ahx/openapi_first" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andreas Haller".freeze]
  s.date = "1980-01-02"
  s.email = ["andreas.haller@posteo.de".freeze]
  s.homepage = "https://github.com/ahx/openapi_first".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "OpenAPI based request validation, response validation, contract-testing and coverage".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<hana>.freeze, ["~> 1.3"])
  s.add_runtime_dependency(%q<json_schemer>.freeze, [">= 2.1", "< 3.0"])
  s.add_runtime_dependency(%q<openapi_parameters>.freeze, [">= 0.6.1", "< 2.0"])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 2.2", "< 4.0"])
end
