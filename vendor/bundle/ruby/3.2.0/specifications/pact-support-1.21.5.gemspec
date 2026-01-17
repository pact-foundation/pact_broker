# -*- encoding: utf-8 -*-
# stub: pact-support 1.21.5 ruby lib

Gem::Specification.new do |s|
  s.name = "pact-support".freeze
  s.version = "1.21.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Fraser".freeze, "Sergei Matheson".freeze, "Brent Snook".freeze, "Ronald Holshausen".freeze, "Beth Skurrie".freeze]
  s.date = "1980-01-02"
  s.email = ["james.fraser@alumni.swinburne.edu".freeze, "sergei.matheson@gmail.com".freeze, "brent@fuglylogic.com".freeze, "uglyog@gmail.com".freeze, "bskurrie@dius.com.au".freeze]
  s.homepage = "https://github.com/pact-foundation/pact-support".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Shared code for Pact gems".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rainbow>.freeze, ["~> 3.1.1"])
  s.add_runtime_dependency(%q<amazing_print>.freeze, ["~> 2.0"])
  s.add_runtime_dependency(%q<diff-lcs>.freeze, ["~> 1.6"])
  s.add_runtime_dependency(%q<expgen>.freeze, ["~> 0.1"])
  s.add_runtime_dependency(%q<string_pattern>.freeze, ["~> 2.0"])
  s.add_runtime_dependency(%q<json>.freeze, ["~> 2.12.2"])
  s.add_runtime_dependency(%q<logger>.freeze, ["< 2.0"])
  s.add_development_dependency(%q<stringio>.freeze, ["~> 3"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 2.14", "< 4.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.18.1"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<fakefs>.freeze, ["~> 2.4.0"])
  s.add_development_dependency(%q<irb>.freeze, [">= 0"])
  s.add_development_dependency(%q<fiddle>.freeze, [">= 0"])
  s.add_development_dependency(%q<hashie>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 0"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
  s.add_development_dependency(%q<conventional-changelog>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<bump>.freeze, ["~> 0.5"])
  s.add_development_dependency(%q<base64>.freeze, ["~> 0.2"])
  s.add_development_dependency(%q<ostruct>.freeze, [">= 0"])
end
