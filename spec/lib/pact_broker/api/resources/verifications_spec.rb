require 'spec_helper'
require 'pact_broker/api/resources/verifications'
require 'pact_broker/pacts/service'
require 'pact_broker/verifications/service'

module PactBroker
  module Api

    module Resources

      describe Verifications do

        describe "post" do

          let(:url) { "/pacts/provider/Provider/consumer/Consumer/versions/1.2.3/verifications" }
          let(:request_body) { {}.to_json }

          subject { post url, request_body, {'CONTENT_TYPE' => 'application/json' }; last_response }

          it "looks up the specified pact" do
            allow(Pacts::Service).to receive(:find_pact).with(instance_of(PactBroker::Pacts::PactParams))
          end

          context "when the pact does not exist" do
            before do
              allow(Pacts::Service).to receive(:find_pact).and_return(nil)
            end

            it "returns a 404" do
              expect(subject.status).to eq 404
            end
          end

          context "when the pact exists" do
            let(:pact) { instance_double("PactBroker::Domain::Pact") }

            before do
              allow(Pacts::Service).to receive(:find_pact).and_return(pact)
              allow(PactBroker::Verifications::Service).to receive(:next_number_for).and_return("2")
            end

            it "returns a 201" do
              expect(subject.status).to eq 201
            end

            it "returns the path of the newly created resource in the headers" do
              expect(subject.headers['Location']).to end_with("/verifications/2")
            end
          end
        end
      end
    end
  end
end