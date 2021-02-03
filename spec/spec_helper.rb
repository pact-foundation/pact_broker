$: << File.expand_path("../../", __FILE__)

RACK_ENV = ENV['RACK_ENV'] = 'test'
require 'spec/support/simplecov'

require 'support/logging'
require 'support/database'
require 'rack/test'
require 'pact_broker/api'
require 'rspec/its'
require 'rspec/pact/matchers'
require 'sucker_punch/testing/inline'
require 'webmock/rspec'
require 'pact_broker/policies'

Dir.glob("./spec/support/**/*.rb") { |file| require file  }

WebMock.disable_net_connect!(allow_localhost: true)

I18n.config.enforce_available_locales = false

RSpec.configure do | config |
  config.before :each do
    PactBroker.reset_configuration
    PactBroker.configuration.seed_example_data = false
    PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = false
    require 'pact_broker/badges/service'
    PactBroker::Badges::Service.clear_cache
  end

  config.after :suite do
    Pact::Fixture.check_fixtures
  end

  config.include Rack::Test::Methods
  config.include Pact::Fixture

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end

  config.include FixtureHelpers
  config.include_context "test data builder"
  config.example_status_persistence_file_path = "./spec/examples.txt"
  config.filter_run_excluding skip: true

  config.after(:each) do | example, something |
    if example.exception.is_a?(Approvals::ApprovalError)
      require "pact/support"
      parts = example.exception.message.split('"')
      received_file = parts[1]
      approved_file = parts[3]
      received_hash = JSON.parse(File.read(received_file))
      approved_hash = JSON.parse(File.read(approved_file))
      diff = Pact::Matchers.diff(approved_hash, received_hash)
      puts Pact::Matchers::UnixDiffFormatter.call(diff)
    end
  end

  def app
    PactBroker::API
  end
end

if ENV["DEBUG"] == "true"
  SemanticLogger.add_appender(io: $stdout)
  SemanticLogger.default_level = :info
end
