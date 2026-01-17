# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec/pact/matchers/version'

Gem::Specification.new do |spec|
  spec.name          = "rspec-pact-matchers"
  spec.version       = Rspec::Pact::Matchers::VERSION
  spec.authors       = ["Beth Skurrie", "Mike Williams"]
  spec.email         = ["beth@bethesque.com", "mdub@dogbiscuit.org"]

  spec.summary       = %q{RSpec matcher using the Pact matching logic}
  spec.homepage      = "http://pact.io"
  spec.license       = "MIT"

  # # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "pact-support", ">=1.1.2", "<2.0"
  spec.add_runtime_dependency "rspec", "~> 3.0"
  spec.add_runtime_dependency 'term-ansicolor', '~> 1.0'

  spec.add_development_dependency "rake", "~> 13.0"
end
