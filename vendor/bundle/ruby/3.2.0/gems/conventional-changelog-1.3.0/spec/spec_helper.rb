require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require 'pp'
require 'fakefs'
require 'conventional_changelog'

RSpec.configure do |config|
  config.before(:all) { FakeFS.activate! }
  config.after(:all) { FakeFS.deactivate! }
end
