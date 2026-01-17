# -*- encoding: utf-8 -*-
# stub: sequel-annotate 1.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "sequel-annotate".freeze
  s.version = "1.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/jeremyevans/sequel-annotate/issues", "changelog_uri" => "https://github.com/jeremyevans/sequel-annotate/blob/master/CHANGELOG", "source_code_uri" => "https://github.com/jeremyevans/sequel-annotate" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jeremy Evans".freeze]
  s.date = "2021-05-20"
  s.description = "sequel-annotate annotates Sequel models with schema information.  By\ndefault, it includes information on columns, indexes, and foreign key\nconstraints for the current table.\n\nOn PostgreSQL, this includes more advanced information, including\ncheck constraints, triggers, comments, and foreign keys constraints for other\ntables that reference the current table.\n".freeze
  s.email = "code@jeremyevans.net".freeze
  s.extra_rdoc_files = ["README.rdoc".freeze, "CHANGELOG".freeze, "MIT-LICENSE".freeze]
  s.files = ["CHANGELOG".freeze, "MIT-LICENSE".freeze, "README.rdoc".freeze]
  s.homepage = "http://github.com/jeremyevans/sequel-annotate".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--quiet".freeze, "--line-numbers".freeze, "--inline-source".freeze, "--title".freeze, "sequel-annotate: Annotate Sequel models with schema information".freeze, "--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Annotate Sequel models with schema information".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<sequel>.freeze, [">= 4"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 5"])
  s.add_development_dependency(%q<minitest-global_expectations>.freeze, [">= 0"])
  s.add_development_dependency(%q<pg>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
end
