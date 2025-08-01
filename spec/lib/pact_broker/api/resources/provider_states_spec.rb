require "pact_broker/api/resources/provider_states"
require "pact_broker/application_context"
require "pact_broker/pacts/provider_state_service"

module PactBroker
  module Api
    module Resources
      describe ProviderStates do
        before do
          allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(provider)
          allow(PactBroker::Pacts::ProviderStateService).to receive(:list_provider_states).and_return(provider_states)
        end

        let(:provider) { double("Example API") }
        let(:base_path) { "/pacts/provider/Example%20API/provider-states" }
        let(:json) { 
          { "providerStates":
          [
            {"name":"an error occurs retrieving an alligator", "consumers":["foo"]},
            {"name":"there is an alligator named Mary", "consumers":["bar","foo"]},
            {"name":"there is not an alligator named Mary", "consumers":["bar"]}
          ]}.to_json
        }

        let(:provider_states) do
          [
            { "providerStates" =>
              [
                PactBroker::Pacts::ProviderState.new(name: "there is an alligator named Mary", params: nil),
                PactBroker::Pacts::ProviderState.new(name: "there is not an alligator named Mary", params: nil),
              ],
              "consumer" => "bar"
            },
            { "providerStates" =>
              [
                PactBroker::Pacts::ProviderState.new(name: "there is an alligator named Mary", params: nil),
                PactBroker::Pacts::ProviderState.new(name: "an error occurs retrieving an alligator", params: nil)
              ],
              "consumer" => "foo"
            }
          ]
        end
        describe "GET - provider states" do

          describe "GET - provider states where they exist" do
            subject { get base_path; last_response }

            it "attempts to find the ProviderStates" do
              expect(PactBroker::Pacts::ProviderStateService).to receive(:list_provider_states)
              subject
            end

            it "returns a 200 response status" do
              expect(subject.status).to eq 200
            end

            it "returns the correct JSON body" do
              expect(subject.body).to eq json
            end

            it "returns the correct content type" do
              expect(subject.headers["Content-Type"]).to include("application/hal+json")
            end
          end

        describe "GET - provider states where do not exist" do
          let(:provider_states) { [] }
          let(:json) { { "providerStates": [] }.to_json }
          subject { get base_path; last_response }

          it "returns a 200 response status" do
            expect(subject.status).to eq 200
          end

          it "returns the correct JSON body" do
            expect(subject.body).to eq json
          end

          it "returns the correct content type" do
            expect(subject.headers["Content-Type"]).to include("application/hal+json")
          end
        end

        describe "GET - where provider does not exist" do
          let(:provider) { nil }
          let(:json) { {"error":"No provider with name 'Example API' found"}.to_json }
          subject { get base_path; last_response }

          it "returns a 404 response status" do
            expect(subject.status).to eq 404
          end

          it "returns the correct JSON error body" do
            expect(subject.body).to eq json
          end

          it "returns the correct content type" do
            expect(subject.headers["Content-Type"]).to include("application/hal+json")
          end
        end
        end

        describe "GET - provider states for environment" do
          let(:environment) { "test-env" }
          let(:env_path) { "#{base_path}/environment/#{environment}" }
          let(:json) { 
            { "providerStates":
            [
              {"name":"an error occurs retrieving an alligator", "consumers":["foo"]},
              {"name":"there is an alligator named Mary", "consumers":["bar","foo"]},
              {"name":"there is not an alligator named Mary", "consumers":["bar"]}
            ]}.to_json
          }

          subject { get env_path; last_response }

          it "calls list_provider_states with environment" do
            expect(PactBroker::Pacts::ProviderStateService).to receive(:list_provider_states).with(provider, nil, environment)
            subject
          end

          it "returns a 200 response status" do
            expect(subject.status).to eq 200
          end

          it "returns the correct JSON body" do
            expect(subject.body).to eq json
          end

          it "returns the correct content type" do
            expect(subject.headers["Content-Type"]).to include("application/hal+json")
          end

          context "when provider states do not exist for environment" do
            let(:provider_states) { [] }
            let(:json) { { "providerStates": [] }.to_json }

            it "returns a 200 response status" do
              expect(subject.status).to eq 200
            end

            it "returns the correct JSON body" do
              expect(subject.body).to eq json
            end
          end

          context "when provider does not exist" do
            let(:provider) { nil }
            let(:json) { {"error":"No provider with name 'Example API' found"}.to_json }

            it "returns a 404 response status" do
              expect(subject.status).to eq 404
            end

            it "returns the correct JSON error body" do
              expect(subject.body).to eq json
            end
          end
        end

        describe "GET - provider states for branch" do
          let(:branch) { "main" }
          let(:branch_path) { "#{base_path}/branch/#{branch}" }
          let(:json) { 
            { "providerStates":
            [
              {"name":"an error occurs retrieving an alligator", "consumers":["foo"]},
              {"name":"there is an alligator named Mary", "consumers":["bar","foo"]},
              {"name":"there is not an alligator named Mary", "consumers":["bar"]}
            ]}.to_json
          }

          subject { get branch_path; last_response }

          it "calls list_provider_states with branch" do
            expect(PactBroker::Pacts::ProviderStateService).to receive(:list_provider_states).with(provider, branch, nil)
            subject
          end

          it "returns a 200 response status" do
            expect(subject.status).to eq 200
          end

          it "returns the correct JSON body" do
            expect(subject.body).to eq json
          end

          it "returns the correct content type" do
            expect(subject.headers["Content-Type"]).to include("application/hal+json")
          end

          context "when provider states do not exist for branch" do
            let(:provider_states) { [] }
            let(:json) { { "providerStates": [] }.to_json }

            it "returns a 200 response status" do
              expect(subject.status).to eq 200
            end

            it "returns the correct JSON body" do
              expect(subject.body).to eq json
            end
          end

          context "when provider does not exist" do
            let(:provider) { nil }
            let(:json) { {"error":"No provider with name 'Example API' found"}.to_json }

            it "returns a 404 response status" do
              expect(subject.status).to eq 404
            end

            it "returns the correct JSON error body" do
              expect(subject.body).to eq json
            end
          end
        end
      end
    end
  end
end