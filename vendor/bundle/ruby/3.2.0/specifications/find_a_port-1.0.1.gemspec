# -*- encoding: utf-8 -*-
# stub: find_a_port 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "find_a_port".freeze
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Wilger".freeze]
  s.date = "2012-07-27"
  s.description = "Use a TCPServer hack to find an open TCP port".freeze
  s.email = "johnwilger@gmail.com".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "http://github.com/jwilger/find_a_port".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Find an open TCP port".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_development_dependency(%q<rspec>.freeze, ["~> 2.8.0"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.7"])
  s.add_development_dependency(%q<rdoc>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<redcarpet>.freeze, [">= 0"])
  s.add_development_dependency(%q<jeweler>.freeze, ["~> 1.8.3"])
  s.add_development_dependency(%q<reek>.freeze, ["~> 1.2.8"])
end
