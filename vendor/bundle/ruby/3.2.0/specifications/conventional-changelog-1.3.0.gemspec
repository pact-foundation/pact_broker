# -*- encoding: utf-8 -*-
# stub: conventional-changelog 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "conventional-changelog".freeze
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Diego Carrion".freeze]
  s.date = "2017-08-14"
  s.description = "".freeze
  s.email = ["dc.rec1@gmail.com".freeze]
  s.executables = ["conventional-changelog".freeze]
  s.files = ["bin/conventional-changelog".freeze]
  s.homepage = "https://github.com/dcrec1/conventional-changelog-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Ruby binary to generate a conventional changelog \u2014 Edit".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.2"])
  s.add_development_dependency(%q<fakefs>.freeze, [">= 0"])
  s.add_development_dependency(%q<codeclimate-test-reporter>.freeze, ["~> 0.1"])
end
