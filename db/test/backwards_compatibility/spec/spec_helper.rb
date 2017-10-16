require 'support/fixture_helpers'
require 'support/request_helpers'
require 'rack/test'

RSpec.configure do | config |

  config.include Rack::Test::Methods
  config.include RequestHelpers
  config.include FixtureHelpers

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.after(:suite) do
    puts "***************************************************************************"
    puts "Pact Broker logs are in db/test/backwards_compatibility/log/pact_broker.log"
    puts "***************************************************************************"
  end
end
