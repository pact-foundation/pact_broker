require "pact_broker/api/middleware/http_debug_logs"

module PactBroker
  module Api
    module Middleware
      describe HttpDebugLogs do
        include Rack::Test::Methods

        before do
          allow(app).to receive(:logger).and_return(logger)
        end

        let(:target_app) { double("app", call: [200, { "Content-Type" => "text/plain" }, ["response body"]]) }
        let(:app) { HttpDebugLogs.new(target_app) }
        let(:logger) { double("logger", debug: nil) }

        subject { post("/", { foo: "bar" }.to_json, { "HTTP_ACCEPT" => "foo" }) }

        it "returns the response" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to eq "text/plain"
          expect(subject.body).to eq "response body"
        end

        it "logs the rack env" do
          expect(logger).to receive(:debug).with("env", payload: hash_including({ "rack.input" => { "foo" => "bar" }, "HTTP_ACCEPT" => "foo" }))
          subject
        end

        it "logs the response" do
          expected_payload = { "status" => 200, "headers" => { "Content-Type" => "text/plain" }, "body" => ["response body"] }
          expect(logger).to receive(:debug).with("response", payload: hash_including(expected_payload))
          subject
        end
      end
    end
  end
end