require 'spec_helper'
require 'pact_broker/ui/controllers/relationships'

require 'rack/test'

module PactBroker
  module UI
    module Controllers
      describe Relationships do

        include Rack::Test::Methods

        let(:app) { Relationships }

        describe "/" do
          describe "GET" do

            before do
              ProviderStateBuilder.new
                .create_consumer
                .create_provider
                .create_consumer_version
                .create_pact
                .create_webhook
                .create_verification
            end

            it "does something" do
              get "/"
              expect(last_response.body).to include("Pacts")
              expect(last_response.status).to eq(200)
            end

          end
        end
      end
    end
  end
end