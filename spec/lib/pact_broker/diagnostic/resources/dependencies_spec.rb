require "pact_broker/diagnostic/app"
require "rack/test"

module PactBroker
  module Diagnostic
    module Resources
      describe Dependencies do

        describe "GET /diagnostic/status/dependencies" do

          include Rack::Test::Methods

          let(:app) { PactBroker::Diagnostic::App.new }
          let(:parsed_response_body) { JSON.parse(subject.body) }

          subject { get "/diagnostic/status/dependencies"; last_response }

          it "returns application/hal+json" do
            expect(subject.headers["Content-Type"]).to eq "application/hal+json"
          end

          it "returns a link to itself" do
            expect(parsed_response_body["_links"]["self"]["href"]).to eq "http://example.org/diagnostic/status/dependencies"
          end

          context "when we can connect to the database" do
            before do
              allow(PactBroker::DB.connection).to receive(:valid_connection?).and_return(true)
            end

            it "returns a 200 response" do
              expect(subject.status).to eq 200
            end

            it "indicates that the database connectivity is OK" do
              expect(parsed_response_body["database"]["ok"]).to be true
            end
          end

          context "when we can't connect to the database" do
            before do
              allow(PactBroker::DB.connection).to receive(:valid_connection?).and_return(false)
            end

            it "returns a 500 response" do
              expect(subject.status).to eq 500
            end

            it "indicates that the database connectivity is not OK" do
              expect(parsed_response_body["database"]["ok"]).to be false
            end
          end

          context "when there is an exception valiating the database connection" do

            class TestError < StandardError; end

            before do
              allow(PactBroker::DB.connection).to receive(:valid_connection?).and_raise(TestError.new("a message"))
            end

            it "returns a 500 response" do
              expect(subject.status).to eq 500
            end

            it "indicates that the database connectivity is not OK" do
              expect(parsed_response_body["database"]["ok"]).to be false
            end

            it "includes an error message" do
              expect(parsed_response_body["database"]["error"]["message"]).to eq "PactBroker::Diagnostic::Resources::TestError - a message"
            end

            it "logs the error" do
              logger = double("Logger")
              allow_any_instance_of(PactBroker::Diagnostic::Resources::Dependencies).to receive(:logger).and_return(logger)
              expect(logger).to receive(:error).with(/TestError.*a message/)
              subject
            end
          end
        end
      end
    end
  end
end
