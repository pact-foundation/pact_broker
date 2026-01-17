# -*- encoding: utf-8 -*-
# stub: ruby-next-core 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-next-core".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-next/ruby-next/issues", "changelog_uri" => "https://github.com/ruby-next/ruby-next/blob/master/CHANGELOG.md", "documentation_uri" => "https://github.com/ruby-next/ruby-next/blob/master/README.md", "funding_uri" => "https://github.com/sponsors/palkan", "homepage_uri" => "https://github.com/ruby-next/ruby-next", "source_code_uri" => "https://github.com/ruby-next/ruby-next" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Vladimir Dementyev".freeze]
  s.date = "1980-01-02"
  s.description = "\n    Ruby Next Core is a zero deps version of Ruby Next meant to be used\n    as as dependency in your gems.\n\n    It contains all the polyfills and utility files but doesn't require transpiler\n    dependencies to be install.\n  ".freeze
  s.email = ["dementiev.vm@gmail.com".freeze]
  s.executables = ["ruby-next".freeze]
  s.files = ["bin/ruby-next".freeze]
  s.homepage = "https://github.com/ruby-next/ruby-next".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Ruby Next core functionality".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<require-hooks>.freeze, ["~> 0.2"])
  s.add_development_dependency(%q<ruby-next-parser>.freeze, [">= 3.4.0.2"])
  s.add_development_dependency(%q<unparser>.freeze, ["~> 0.6.0"])
  s.add_development_dependency(%q<paco>.freeze, ["~> 0.2"])
end
