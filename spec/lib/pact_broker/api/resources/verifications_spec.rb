require "pact_broker/api/resources/verifications"
require "pact_broker/pacts/service"
require "pact_broker/verifications/service"

module PactBroker
  module Api
    module Resources
      describe Verifications do
        describe "post" do
          let(:url) { "/pacts/provider/Provider/consumer/Consumer/pact-version/1234/metadata/abcd/verification-results" }
          let(:request_body) { { some: "params" }.to_json }
          let(:rack_env) do
            { "CONTENT_TYPE" => "application/json", "pactbroker.database_connector" => database_connector }
          end
          let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }
          let(:database_connector) { double("database_connector" )}
          let(:verification) { double(PactBroker::Domain::Verification) }
          let(:parsed_metadata) { { the: "metadata", consumer_version_number: "2", pending: true } }
          let(:base_url) { "http://example.org" }
          let(:webhook_execution_configuration) { instance_double(PactBroker::Webhooks::ExecutionConfiguration) }
          let(:errors) { {} }

          before do
            allow_any_instance_of(Verifications).to receive(:handle_webhook_events) { |&block| block.call }
            allow(PactBroker::Verifications::Service).to receive(:create).and_return(verification)
            allow(PactBroker::Api::Contracts::VerificationContract).to receive(:call).and_return(double("result", errors: errors))
            allow(PactBrokerUrls).to receive(:decode_pact_metadata).and_return(parsed_metadata)
          end

          subject { post(url, request_body, rack_env) }

          it "looks up the specified pact" do
            expect(Pacts::Service).to receive(:find_pact) do | arg |
              expect(arg).to be_a(PactBroker::Pacts::PactParams)
              expect(arg[:consumer_version_number]).to eq "2"
            end
            subject
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
            let(:pact) do
              instance_double("PactBroker::Domain::Pact",
                provider_name: "Provider",
                consumer_name: "Consumer",
                pact_version_sha: "1234"
              )
            end
            let(:next_verification_number) { "2" }
            let(:serialised_verification) { {some: "verification"}.to_json }
            let(:decorator) { instance_double("PactBroker::Api::Decorators::VerificationDecorator", to_json: serialised_verification) }

            before do
              allow(Pacts::Service).to receive(:find_pact).and_return(pact)
              allow(Pacts::Service).to receive(:find_for_verification_publication).and_return(verified_pacts)
              allow(PactBroker::Verifications::Service).to receive(:next_number).and_return(next_verification_number)
              allow(PactBroker::Api::Decorators::VerificationDecorator).to receive(:new).and_return(decorator)
              allow(PactBroker.configuration).to receive(:show_webhook_response?).and_return("some-boolean")
            end

            let(:verified_pacts) { double("verified pacts") }

            it "parses the webhook metadata" do
              expect(PactBrokerUrls).to receive(:decode_pact_metadata).with("abcd")
              subject
            end

            it "returns a 201" do
              expect(subject.status).to eq 201
            end

            it "returns the path of the newly created resource in the headers" do
              expect(subject.headers["Location"]).to eq("http://example.org/pacts/provider/Provider/consumer/Consumer/pact-version/1234/verification-results/2")
            end

            it "stores the verification in the database" do
              expect(PactBroker::Verifications::Service).to receive(:create).with(
                next_verification_number,
                hash_including("some" => "params", "wip" => false, "pending" => true),
                verified_pacts,
                parsed_metadata
              )
              subject
            end

            it "serialises the newly created verification" do
              expect(PactBroker::Api::Decorators::VerificationDecorator).to receive(:new).with(verification)
              expect(decorator).to receive(:to_json)
              subject
            end

            it "returns the serialised verification in the response body" do
              expect(subject.body).to eq serialised_verification
            end

            context "when the verification is for a wip pact" do
              let(:parsed_metadata) { { wip: "true" } }

              it "merges that into the verification params" do
                expect(PactBroker::Verifications::Service).to receive(:create).with(
                  anything,
                  hash_including("wip" => true),
                  anything,
                  anything
                )
                subject
              end
            end
          end

          context "when invalid parameters are used" do
            let(:errors) { { some: ["errors"]} }

            it "returns a 400 status" do
              expect(subject.status).to eq 400
            end

            it "sets errors on the response" do
              expect(response_body[:errors]).to eq errors
            end
          end
        end
      end
    end
  end
end