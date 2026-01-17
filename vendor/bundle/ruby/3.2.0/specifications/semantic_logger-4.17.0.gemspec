# -*- encoding: utf-8 -*-
# stub: semantic_logger 4.17.0 ruby lib

Gem::Specification.new do |s|
  s.name = "semantic_logger".freeze
  s.version = "4.17.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/reidmorrison/semantic_logger/issues", "documentation_uri" => "https://logger.rocketjob.io", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/reidmorrison/semantic_logger/tree/v4.17.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Reid Morrison".freeze]
  s.date = "1980-01-02"
  s.homepage = "https://logger.rocketjob.io".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Feature rich logging framework, and replacement for existing Ruby & Rails loggers.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
end
