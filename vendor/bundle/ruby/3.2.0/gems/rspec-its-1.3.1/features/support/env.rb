require 'aruba/cucumber'
require 'rspec/core'
require 'rspec/its'

Aruba.configure do |config|
  config.before(:command) do |cmd|
    cmd.environment['JRUBY_OPTS'] = "-X-C #{ENV['JRUBY_OPTS']}" # disable JIT since these processes are so short lived
  end
end if RUBY_PLATFORM == 'java'

Aruba.configure do |config|
  config.before(:command) do |cmd|
    cmd.environment['RBXOPT'] = "-Xint=true #{ENV['RBXOPT']}" # disable JIT since these processes are so short lived
  end
end if defined?(Rubinius)
