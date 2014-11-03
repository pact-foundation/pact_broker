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

            let(:consumer) { instance_double("PactBroker::Domain::Pacticipant", name: 'consumer_name')}
            let(:provider) { instance_double("PactBroker::Domain::Pacticipant", name: 'provider_name')}
            let(:relationship) { PactBroker::Domain::Relationship.new(consumer, provider)}
            let(:relationships) { [relationship] }

            before do
              allow(PactBroker::Services::PacticipantService).to receive(:find_relationships).and_return(relationships)
            end

            it "does something" do
              get "/"
              expect(last_response.body).to include("Relationships")
              expect(last_response.status).to eq(200)
            end

          end
        end
      end
    end
  end
end