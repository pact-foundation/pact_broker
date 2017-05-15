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
            let(:pact) { instance_double("PactBroker::Domain::Pact", created_at: Date.new(2017))}
            let(:relationship) { PactBroker::Domain::Relationship.new(consumer, provider, pact)}
            let(:relationships) { [relationship] }

            before do
              allow(PactBroker::Pacticipants::Service).to receive(:find_relationships).and_return(relationships)
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