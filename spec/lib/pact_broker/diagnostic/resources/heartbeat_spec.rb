require 'pact_broker/diagnostic/resources/heartbeat'
require 'pact_broker/diagnostic/app'
require 'rack/test'

module PactBroker
  module Diagnostic
    module Resources
      describe Heartbeat do

        include Rack::Test::Methods

        let(:app) { PactBroker::Diagnostic::App.new }

        describe "GET /diagnostic/status/heartbeat" do

          it "returns a 200" do
            get "/diagnostic/status/heartbeat"
            expect(last_response.status).to eq 200
          end

        end
      end
    end
  end
end
