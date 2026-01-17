# -*- encoding: utf-8 -*-
# stub: sequel 5.100.0 ruby lib

Gem::Specification.new do |s|
  s.name = "sequel".freeze
  s.version = "5.100.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/jeremyevans/sequel/issues", "changelog_uri" => "https://sequel.jeremyevans.net/rdoc/files/CHANGELOG.html", "documentation_uri" => "https://sequel.jeremyevans.net/documentation.html", "mailing_list_uri" => "https://github.com/jeremyevans/sequel/discussions", "source_code_uri" => "https://github.com/jeremyevans/sequel" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jeremy Evans".freeze]
  s.date = "1980-01-02"
  s.description = "The Database Toolkit for Ruby".freeze
  s.email = "code@jeremyevans.net".freeze
  s.executables = ["sequel".freeze]
  s.extra_rdoc_files = ["MIT-LICENSE".freeze]
  s.files = ["MIT-LICENSE".freeze, "bin/sequel".freeze]
  s.homepage = "https://sequel.jeremyevans.net".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--quiet".freeze, "--line-numbers".freeze, "--inline-source".freeze, "--title".freeze, "Sequel: The Database Toolkit for Ruby".freeze, "--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "The Database Toolkit for Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 5.7.0"])
  s.add_development_dependency(%q<minitest-hooks>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest-global_expectations>.freeze, [">= 0"])
  s.add_development_dependency(%q<tzinfo>.freeze, [">= 0"])
  s.add_development_dependency(%q<activemodel>.freeze, [">= 0"])
  s.add_development_dependency(%q<nokogiri>.freeze, [">= 0"])
end
