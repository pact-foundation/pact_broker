# -*- encoding: utf-8 -*-
# stub: reform 2.6.2 ruby lib

Gem::Specification.new do |s|
  s.name = "reform".freeze
  s.version = "2.6.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nick Sutterer".freeze, "Fran Worley".freeze]
  s.date = "2022-05-24"
  s.description = "Form object decoupled from models.".freeze
  s.email = ["apotonick@gmail.com".freeze, "frances@safetytoolbox.co.uk".freeze]
  s.homepage = "https://github.com/trailblazer/reform".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Form object decoupled from models with validation, population and presentation.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<disposable>.freeze, [">= 0.5.0", "< 1.0.0"])
  s.add_runtime_dependency(%q<representable>.freeze, [">= 3.1.1", "< 4"])
  s.add_runtime_dependency(%q<uber>.freeze, ["< 0.2.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest-line>.freeze, [">= 0"])
  s.add_development_dependency(%q<multi_json>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
