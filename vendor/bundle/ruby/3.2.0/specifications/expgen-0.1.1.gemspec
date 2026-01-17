# -*- encoding: utf-8 -*-
# stub: expgen 0.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "expgen".freeze
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jonas Nicklas".freeze]
  s.date = "2013-04-02"
  s.description = "Generate random strings from regular expression".freeze
  s.email = ["jonas.nicklas@gmail.com".freeze]
  s.executables = ["expgen".freeze]
  s.files = ["bin/expgen".freeze]
  s.homepage = "".freeze
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Generate random regular expression".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_runtime_dependency(%q<parslet>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
