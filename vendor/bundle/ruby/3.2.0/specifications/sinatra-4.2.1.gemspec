# -*- encoding: utf-8 -*-
# stub: sinatra 4.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "sinatra".freeze
  s.version = "4.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/sinatra/sinatra/issues", "changelog_uri" => "https://github.com/sinatra/sinatra/blob/main/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/sinatra", "homepage_uri" => "http://sinatrarb.com/", "mailing_list_uri" => "http://groups.google.com/group/sinatrarb", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/sinatra/sinatra" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Blake Mizerany".freeze, "Ryan Tomayko".freeze, "Simon Rozet".freeze, "Konstantin Haase".freeze]
  s.date = "1980-01-02"
  s.description = "Sinatra is a DSL for quickly creating web applications in Ruby with minimal effort.".freeze
  s.email = "sinatrarb@googlegroups.com".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "http://sinatrarb.com/".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--line-numbers".freeze, "--title".freeze, "Sinatra".freeze, "--main".freeze, "README.rdoc".freeze, "--encoding=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.8".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Classy web-development dressed in a DSL".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<logger>.freeze, [">= 1.6.0"])
  s.add_runtime_dependency(%q<mustermann>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 3.0.0", "< 4"])
  s.add_runtime_dependency(%q<rack-protection>.freeze, ["= 4.2.1"])
  s.add_runtime_dependency(%q<rack-session>.freeze, [">= 2.0.0", "< 3"])
  s.add_runtime_dependency(%q<tilt>.freeze, ["~> 2.0"])
end
