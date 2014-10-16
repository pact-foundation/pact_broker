require 'spec_helper'
require 'pact_broker/pacts/pact_params'

module PactBroker
  module Pacts
    describe PactParams do

      let(:body) { load_fixture('consumer-provider.json') }
      let(:consumer_version_number) { '1.2.3' }
      let(:headers) { { 'X-Pact-Consumer-Version' => consumer_version_number } }

      describe "from_request" do

        context "from a PUT request" do
          let(:request) { Webmachine::Request.new("PUT", "/", headers, body)}
          let(:path_info) do
            {
              consumer_name: 'Consumer',
              provider_name: 'Provider',
              consumer_version_number: '1.2.3'
            }
          end

          subject { PactParams.from_request(request, path_info) }

          it "extracts the consumer name from the path" do
            expect(subject.consumer_name).to eq "Consumer"
          end

          it "extracts the provider name from the path" do
            expect(subject.provider_name).to eq "Provider"
          end

          it "extracts the consumer_version_number from the path" do
            expect(subject.consumer_version_number).to eq "1.2.3"
          end

          it "extracts the json_content" do
            expect(subject.json_content).to eq body
          end

          it "extracts the consumer name from the pact" do
            expect(subject.consumer_name_in_pact).to eq "A Consumer"
          end

          it "extracts the provider name from the pact" do
            expect(subject.provider_name_in_pact).to eq "A Provider"
          end
        end

      end

      describe "from_post_request" do

        let(:request) { Webmachine::Request.new("POST", "/pacts", headers, body)}

        subject { PactParams.from_post_request(request) }

        it "extracts the consumer name" do
          expect(subject.consumer_name).to eq "A Consumer"
        end

        it "extracts the provider name" do
          expect(subject.provider_name).to eq "A Provider"
        end

        it "extracts the consumer_version_number" do
          expect(subject.consumer_version_number).to eq "1.2.3"
        end

        it "extracts the json_content" do
          expect(subject.json_content).to eq body
        end


        context "with missing data" do
          let(:request) { Webmachine::Request.new("POST", "/pacts", {}, {}.to_json )}

          it "the consumer name is nil" do
            expect(subject.consumer_name).to be nil
          end

          it "the provider name is nil" do
            expect(subject.provider_name).to be nil
          end

          it "the consumer_version_number is nil" do
            expect(subject.consumer_version_number).to be nil
          end

          it "extracts the json_content" do
            expect(subject.json_content).to eq '{}'
          end
        end

      end
    end
  end
end
