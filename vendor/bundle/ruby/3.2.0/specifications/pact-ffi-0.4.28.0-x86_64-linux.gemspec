# -*- encoding: utf-8 -*-
# stub: pact-ffi 0.4.28.0 x86_64-linux lib

Gem::Specification.new do |s|
  s.name = "pact-ffi".freeze
  s.version = "0.4.28.0"
  s.platform = "x86_64-linux".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yousaf Nabi".freeze]
  s.date = "1980-01-02"
  s.description = "Enables consumer driven contract testing, providing a mock service and DSL for the consumer project, and interaction playback and verification for the service provider project.".freeze
  s.email = ["you@saf.dev".freeze]
  s.homepage = "https://github.com/you54f/pact-ffi".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Pact Reference FFI libpact_ffi library wrapper".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<cucumber>.freeze, ["~> 9.2"])
  s.add_development_dependency(%q<httparty>.freeze, ["~> 0.21.0"])
  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.16"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<webrick>.freeze, ["~> 1.8"])
  s.add_development_dependency(%q<csv>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<ffi>.freeze, ["~> 1.15"])
end
