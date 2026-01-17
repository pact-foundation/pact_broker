# -*- encoding: utf-8 -*-
# stub: pact 1.67.3 ruby lib

Gem::Specification.new do |s|
  s.name = "pact".freeze
  s.version = "1.67.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/pact-foundation/pact-ruby/issues", "changelog_uri" => "https://github.com/pact-foundation/pact-ruby/blob/master/CHANGELOG.md", "documentation_uri" => "https://github.com/pact-foundation/pact-ruby/blob/master/README.md", "source_code_uri" => "https://github.com/pact-foundation/pact-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Fraser".freeze, "Sergei Matheson".freeze, "Brent Snook".freeze, "Ronald Holshausen".freeze, "Beth Skurrie".freeze]
  s.date = "1980-01-02"
  s.description = "Enables consumer driven contract testing, providing a mock service and DSL for the consumer project, and interaction playback and verification for the service provider project.".freeze
  s.email = ["james.fraser@alumni.swinburne.edu".freeze, "sergei.matheson@gmail.com".freeze, "brent@fuglylogic.com".freeze, "uglyog@gmail.com".freeze, "bskurrie@dius.com.au".freeze]
  s.executables = ["pact".freeze]
  s.files = ["bin/pact".freeze]
  s.homepage = "https://github.com/pact-foundation/pact-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Enables consumer driven contract testing, providing a mock service and DSL for the consumer project, and interaction playback and verification for the service provider project.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<faraday>.freeze, ["~> 2.0", "< 3.0"])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.3"])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rack-proxy>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<webrick>.freeze, ["~> 1.8"])
  s.add_development_dependency(%q<combustion>.freeze, [">= 1.3"])
  s.add_development_dependency(%q<sbmt-kafka_consumer>.freeze, [">= 2.0.1"])
  s.add_development_dependency(%q<sbmt-kafka_producer>.freeze, [">= 1.0"])
  s.add_development_dependency(%q<gruf>.freeze, [">= 2.18"])
  s.add_development_dependency(%q<gruf-rspec>.freeze, [">= 0.6.0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
  s.add_development_dependency(%q<vcr>.freeze, [">= 6.0"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 2.4"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 2.2"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0"])
  s.add_development_dependency(%q<standard>.freeze, [">= 1.35.1"])
  s.add_runtime_dependency(%q<rack-test>.freeze, [">= 0.6.3", "< 3.0.0"])
  s.add_runtime_dependency(%q<thor>.freeze, [">= 0.20", "< 2.0"])
  s.add_runtime_dependency(%q<rainbow>.freeze, ["~> 3.1"])
  s.add_runtime_dependency(%q<string_pattern>.freeze, ["~> 2.0"])
  s.add_runtime_dependency(%q<jsonpath>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<pact-support>.freeze, ["~> 1.21", ">= 1.21.2"])
  s.add_runtime_dependency(%q<pact-mock_service>.freeze, ["~> 3.0", ">= 3.3.1"])
  s.add_development_dependency(%q<fakefs>.freeze, ["= 2.4"])
  s.add_development_dependency(%q<hashie>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<faraday-multipart>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<conventional-changelog>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<bump>.freeze, ["~> 0.5"])
  s.add_development_dependency(%q<pact-message>.freeze, ["~> 0.8"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<ostruct>.freeze, [">= 0"])
end
