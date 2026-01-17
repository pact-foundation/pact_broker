# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'lib', 'jsonpath', 'version')

Gem::Specification.new do |s|
  s.name = 'jsonpath'
  s.version = JsonPath::VERSION
  s.required_ruby_version = '>= 2.6'
  s.authors = ['Joshua Hull', 'Gergely Brautigam']
  s.summary = 'Ruby implementation of http://goessner.net/articles/JsonPath/'
  s.description = 'Ruby implementation of http://goessner.net/articles/JsonPath/.'
  s.email = ['joshbuddy@gmail.com', 'skarlso777@gmail.com']
  s.extra_rdoc_files = ['README.md']
  s.files = `git ls-files`.split("\n")
  s.homepage = 'https://github.com/joshbuddy/jsonpath'
  s.test_files = `git ls-files`.split("\n").select { |f| f =~ /^spec/ }
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.licenses    = ['MIT']

  # dependencies
  s.add_runtime_dependency 'multi_json'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'code_stats'
  s.add_development_dependency 'minitest', '~> 2.2.0'
  s.add_development_dependency 'phocus'
  s.add_development_dependency 'racc'
  s.add_development_dependency 'rake'
end
