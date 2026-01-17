# -*- encoding: utf-8 -*-
# stub: string_pattern 2.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "string_pattern".freeze
  s.version = "2.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mario Ruiz".freeze]
  s.date = "2022-09-20"
  s.description = "Easily generate strings supplying a very simple pattern. '10-20:Xn/x/'.generate #>qBstvc6JN8ra. Generate random strings using a regular expression (Regexp): /[a-z0-9]{2,5}w+/.gen . Also generate words in English or Spanish. Perfect to be used in test data factories. Also, validate if a text fulfills a specific pattern or even generate a string following a pattern and returning the wrong length, value... for testing your applications.".freeze
  s.email = "marioruizs@gmail.com".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://github.com/MarioRuiz/string_pattern".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Generate easily random strings following a simple pattern or regular expression. '10-20:Xn/x/'.generate #>qBstvc6JN8ra. Also generate words in English or Spanish. Perfect to be used in test data factories.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<regexp_parser>.freeze, ["~> 2.5", ">= 2.5.0"])
end
