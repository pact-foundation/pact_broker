# frozen_string_literal: true

require_relative 'lib/moments/version'

Gem::Specification.new do |spec|
  spec.name        = 'moments'
  spec.version     = Moments.gem_version
  spec.authors     = ['Tim Rudat']
  spec.email       = ['timrudat@gmail.com']
  spec.summary     = 'Handles time differences.'
  spec.description = ''
  spec.homepage    = 'https://github.com/excpt/moments'
  spec.license     = 'MIT'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'github_changelog_generator'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'timecop'
end
