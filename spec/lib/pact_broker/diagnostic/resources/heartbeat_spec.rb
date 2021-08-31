require "pact_broker/diagnostic/resources/heartbeat"
require "pact_broker/diagnostic/app"
require "rack/test"

module PactBroker
  module Diagnostic
    module Resources
      describe Heartbeat do
        include Rack::Test::Methods

        let(:app) { PactBroker::Diagnostic::App.new }

        describe "GET /diagnostic/status/heartbeat" do
          let(:rack_env) { { "pactbroker.base_url" => "http://pact-broker"} }
          let(:parsed_response_body) { JSON.parse(subject.body) }

          subject { get("/diagnostic/status/heartbeat", nil, rack_env) }

          it "returns a 200" do
            expect(subject.status).to eq 200
          end

          it "returns application/hal+json" do
            expect(subject.headers["Content-Type"]).to eq "application/hal+json"
          end

          it "returns a link to itself" do
            expect(parsed_response_body["_links"]["self"]["href"]).to eq "http://pact-broker/diagnostic/status/heartbeat"
          end
        end
      end
    end
  end
end
