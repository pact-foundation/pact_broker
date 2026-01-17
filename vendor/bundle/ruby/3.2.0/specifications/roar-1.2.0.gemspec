# -*- encoding: utf-8 -*-
# stub: roar 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "roar".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nick Sutterer".freeze]
  s.date = "2023-01-17"
  s.description = "Object-oriented representers help you defining nested REST API documents which can then be rendered and parsed using one and the same concept.".freeze
  s.email = ["apotonick@gmail.com".freeze]
  s.homepage = "http://trailblazer.to/gems/roar".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Parse and render REST API documents using representers.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<representable>.freeze, ["~> 3.1"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<test_xml>.freeze, ["= 0.1.6"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 5.10"])
  s.add_development_dependency(%q<sinatra>.freeze, [">= 0"])
  s.add_development_dependency(%q<sinatra-contrib>.freeze, [">= 0"])
  s.add_development_dependency(%q<webrick>.freeze, [">= 0"])
  s.add_development_dependency(%q<faraday>.freeze, [">= 0"])
  s.add_development_dependency(%q<multi_json>.freeze, [">= 0"])
  s.add_development_dependency(%q<dry-types>.freeze, [">= 1.0.0"])
end
