require 'spec_helper'
require 'pact_broker/api/resources/pacts'

module PactBroker
  module Api
    module Resources

      describe Pacts do

        describe "POST" do

          let(:pact_content) { load_fixture('consumer-provider.json') }
          let(:path) { "/pacts" }
          let(:response_body_json) { JSON.parse(subject.body) }
          let(:consumer_version_number) { '1.2.3' }
          let(:rack_env) { {'CONTENT_TYPE' => 'application/json', 'HTTP_X_PACT_CONSUMER_VERSION' => consumer_version_number } }

          subject { post path, pact_content, rack_env; last_response  }

          context "without an X-Pact-Consumer-Version" do

            let(:rack_env) { {'CONTENT_TYPE' => 'application/json' } }

            it "returns a 400 error response" do
              expect(subject).to be_a_json_error_response("Please specify")
            end

          end

          context "with an invalid version number" do
            let(:consumer_version_number) { 'blah' }

            it "returns a 400 error response" do
              expect(subject).to be_a_json_error_response("X-Pact-Consumer-Version 'blah' is not recognised as a standard semantic version.")
            end
          end

          context "with a missing pacticipant name" do

          end
        end

      end
    end

  end
end