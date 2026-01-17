# -*- encoding: utf-8 -*-
# stub: json_schemer 2.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "json_schemer".freeze
  s.version = "2.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Harsha".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.email = ["davishmcclurg@gmail.com".freeze]
  s.executables = ["json_schemer".freeze]
  s.files = ["exe/json_schemer".freeze]
  s.homepage = "https://github.com/davishmcclurg/json_schemer".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "JSON Schema validator. Supports drafts 4, 6, 7, 2019-09, 2020-12, OpenAPI 3.0, and OpenAPI 3.1.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<base64>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.4.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.22"])
  s.add_development_dependency(%q<csv>.freeze, [">= 0"])
  s.add_development_dependency(%q<i18n>.freeze, [">= 0"])
  s.add_development_dependency(%q<i18n-debug>.freeze, [">= 0"])
  s.add_development_dependency(%q<openssl>.freeze, ["~> 3.3.2"])
  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<hana>.freeze, ["~> 1.3"])
  s.add_runtime_dependency(%q<regexp_parser>.freeze, ["~> 2.0"])
  s.add_runtime_dependency(%q<simpleidn>.freeze, ["~> 0.2"])
end
