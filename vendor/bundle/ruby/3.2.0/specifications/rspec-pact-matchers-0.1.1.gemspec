# -*- encoding: utf-8 -*-
# stub: rspec-pact-matchers 0.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-pact-matchers".freeze
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Beth Skurrie".freeze, "Mike Williams".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-09-10"
  s.email = ["beth@bethesque.com".freeze, "mdub@dogbiscuit.org".freeze]
  s.homepage = "http://pact.io".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "RSpec matcher using the Pact matching logic".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<pact-support>.freeze, [">= 1.1.2", "< 2.0"])
  s.add_runtime_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<term-ansicolor>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
end
