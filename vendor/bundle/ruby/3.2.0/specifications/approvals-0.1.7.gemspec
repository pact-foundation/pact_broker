# -*- encoding: utf-8 -*-
# stub: approvals 0.1.7 ruby lib

Gem::Specification.new do |s|
  s.name = "approvals".freeze
  s.version = "0.1.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Llewellyn Falco".freeze, "Sam Livingston-Gray".freeze]
  s.date = "2025-02-05"
  s.description = "A library to make it easier to do golden-master style testing in Ruby".freeze
  s.email = ["llewellyn.falco@gmail.com".freeze, "geeksam@gmail.com".freeze]
  s.executables = ["approvals".freeze]
  s.files = ["bin/approvals".freeze]
  s.homepage = "https://github.com/approvals/ApprovalTests.Ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Approval Tests for Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<thor>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<json>.freeze, ["~> 2.0"])
  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.8"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.1"])
end
