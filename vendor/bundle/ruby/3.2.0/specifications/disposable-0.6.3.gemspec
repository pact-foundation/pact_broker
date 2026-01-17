# -*- encoding: utf-8 -*-
# stub: disposable 0.6.3 ruby lib

Gem::Specification.new do |s|
  s.name = "disposable".freeze
  s.version = "0.6.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nick Sutterer".freeze]
  s.date = "2022-05-24"
  s.description = "Decorators on top of your ORM layer.".freeze
  s.email = ["apotonick@gmail.com".freeze]
  s.homepage = "https://github.com/apotonick/disposable".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Decorators on top of your ORM layer with change tracking, collection semantics and nesting.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<declarative>.freeze, [">= 0.0.9", "< 1.0.0"])
  s.add_runtime_dependency(%q<representable>.freeze, [">= 3.1.1", "< 4"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<activerecord>.freeze, [">= 0"])
  s.add_development_dependency(%q<dry-types>.freeze, [">= 0"])
end
