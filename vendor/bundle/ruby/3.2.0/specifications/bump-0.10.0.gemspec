# -*- encoding: utf-8 -*-
# stub: bump 0.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "bump".freeze
  s.version = "0.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregory Marcilhacy".freeze]
  s.date = "2020-10-08"
  s.email = "g.marcilhacy@gmail.com".freeze
  s.executables = ["bump".freeze]
  s.files = ["bin/bump".freeze]
  s.homepage = "https://github.com/gregorym/bump".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Bump your gem version file".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
end
