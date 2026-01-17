# -*- encoding: utf-8 -*-
# stub: webmachine 2.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "webmachine".freeze
  s.version = "2.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/webmachine/webmachine-ruby/issues", "changelog_uri" => "https://github.com/webmachine/webmachine-ruby/blob/HEAD/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/webmachine/2.0.1", "homepage_uri" => "https://github.com/webmachine/webmachine-ruby", "source_code_uri" => "https://github.com/webmachine/webmachine-ruby", "wiki_uri" => "https://github.com/webmachine/webmachine-ruby/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sean Cribbs".freeze]
  s.date = "2024-02-27"
  s.description = " webmachine is a toolkit for building HTTP applications in a declarative fashion, that avoids the confusion of going through a CGI-style interface like Rack. It is strongly influenced by the original Erlang project of the same name and shares its opinionated nature about HTTP. ".freeze
  s.email = ["sean@basho.com".freeze]
  s.homepage = "https://github.com/webmachine/webmachine-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "webmachine is a toolkit for building HTTP applications,".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<i18n>.freeze, [">= 0.4.0"])
  s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<as-notifications>.freeze, [">= 1.0.2", "< 2.0"])
  s.add_runtime_dependency(%q<base64>.freeze, [">= 0"])
  s.add_development_dependency(%q<webrick>.freeze, ["~> 1.7.0"])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.21"])
end
