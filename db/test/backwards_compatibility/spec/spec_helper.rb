require 'support/fixture_helpers'
require 'rack/test'

RSpec.configure do | config |

  config.include Rack::Test::Methods

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include FixtureHelpers
end
