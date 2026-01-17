# -*- encoding: utf-8 -*-
# stub: padrino-core 0.16.0 ruby lib

Gem::Specification.new do |s|
  s.name = "padrino-core".freeze
  s.version = "0.16.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Padrino Team".freeze, "Nathan Esquenazi".freeze, "Davide D'Agostino".freeze, "Arthur Chiu".freeze]
  s.date = "2025-12-02"
  s.description = "The Padrino core gem required for use of this framework".freeze
  s.email = "padrinorb@gmail.com".freeze
  s.executables = ["padrino".freeze]
  s.extra_rdoc_files = ["README.rdoc".freeze]
  s.files = ["README.rdoc".freeze, "bin/padrino".freeze]
  s.homepage = "http://www.padrinorb.com".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.8".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "The required Padrino core gem".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<padrino-support>.freeze, ["= 0.16.0"])
  s.add_runtime_dependency(%q<rackup>.freeze, ["~> 2.1"])
  s.add_runtime_dependency(%q<sinatra>.freeze, ["~> 4"])
  s.add_runtime_dependency(%q<thor>.freeze, ["~> 1.0"])
end
