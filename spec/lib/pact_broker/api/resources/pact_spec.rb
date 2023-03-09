require "spec_helper"
require "pact_broker/api/resources/pact"
require "rack/test"
require "pact_broker/pacts/service"
require "pact_broker/pacticipants/service"

module PactBroker::Api
  module Resources
    describe Pact do
      include Rack::Test::Methods

      let(:app) { PactBroker::API }
      let(:json) { {some: "json"}.to_json }

      describe "GET" do
        context "Accept: text/html" do

          let(:json_content) { "json_content" }
          let(:pact) { double("pact", json_content: json_content)}
          let(:html) { "html" }
          let(:pact_id_params) { {provider_name: "provider_name", consumer_name: "consumer_name", consumer_version_number: "1.2.3"} }
          let(:html_options) { { base_url: "http://example.org", badge_url: "http://badge" } }

          before do
            allow_any_instance_of(Pact).to receive(:badge_url_for_latest_pact).and_return("http://badge")
            allow_any_instance_of(Pact).to receive(:ui_base_url).and_return("http://example.org")
            allow(PactBroker::Pacts::Service).to receive(:find_pact).and_return(pact)
            allow(PactBroker.configuration.html_pact_renderer).to receive(:call).and_return(html)
          end

          subject { get "/pacts/provider/provider_name/consumer/consumer_name/versions/1.2.3",{}, {"HTTP_ACCEPT" => "text/html"} }

          it "finds the pact" do
            expect(PactBroker::Pacts::Service).to receive(:find_pact).with(hash_including(pact_id_params))
            subject
          end

          it "determines the badge url for the HTML page" do
            expect_any_instance_of(Pact).to receive(:badge_url_for_latest_pact).with(pact, "http://example.org")
            subject
          end

          it "uses the configured HTML renderer" do
            expect(PactBroker.configuration.html_pact_renderer).to receive(:call).with(pact, html_options)
            subject
          end

          it "returns a HTML body" do
            subject
            expect(last_response.body).to eq html
          end

          it "returns a content type of HTML" do
            subject
            expect(last_response.headers["Content-Type"]).to eq "text/html;charset=utf-8"
          end

        end
      end

      shared_examples "an update endpoint" do |http_method|
        subject { self.send http_method, "/pacts/provider/Provider/consumer/Consumer/version/1.2.3", json, {"CONTENT_TYPE" => "application/json"} ; last_response }

        let(:response) { subject; last_response }

        context "with invalid JSON" do
          let(:json) { "{" }

          it "returns a 400 response" do
            expect(response.status).to eq 400
          end

          it "returns a JSON content type" do
            expect(response.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
          end

          it "returns an error message" do
            expect(JSON.parse(response.body)["error"]).to match(/JSON/)
          end
        end

        context "with validation errors" do
          let(:errors) { { messages: ["messages"] } }

          before do
            allow(Contracts::PutPactParamsContract).to receive(:call).and_return(errors)
          end

          it "returns a 400 error" do
            expect(subject).to be_a_json_error_response "messages"
          end
        end

        context "with a potential duplicate pacticipant" do

          let(:pacticipant_service) { PactBroker::Pacticipants::Service }
          let(:messages) { ["message1", "message2"] }

          before do
            allow(pacticipant_service).to receive(:messages_for_potential_duplicate_pacticipants).and_return(messages)
          end

          it "checks for duplicates" do
            expect(pacticipant_service).to receive(:messages_for_potential_duplicate_pacticipants).with(["Consumer", "Provider"], "http://example.org")
            response
          end

          it "returns a 409 response" do
            expect(response.status).to eq 409
          end

          it "returns a text response" do
            expect(response.headers["Content-Type"]).to eq "text/plain"
          end

          it "returns the messages in the response body" do
            expect(response.body).to eq "message1\nmessage2"
          end
        end
      end

      describe "PUT" do
        it_behaves_like "an update endpoint", :put
      end

      describe "PATCH" do
        it_behaves_like "an update endpoint", :patch
      end

      describe "DELETE" do
        before do
          allow(pact_service).to receive(:find_pact).and_return(pact)
          allow(pact_service).to receive(:delete)
          allow(pact_service).to receive(:find_latest_pact).and_return(latest_pact)
          allow_any_instance_of(described_class).to receive(:latest_pact_url).and_return("http://latest-pact")
        end

        let(:pact) { double("pact") }
        let(:pact_service) { PactBroker::Pacts::Service }
        let(:latest_pact) { double("latest pact") }

        subject { delete "/pacts/provider/Provider/consumer/Consumer/version/1.2", json, {"CONTENT_TYPE" => "application/json"} ; last_response }

        context "when the pact exists" do
          it "deletes the pact using the pact service" do
            expect(pact_service).to receive(:delete).with(instance_of(PactBroker::Pacts::PactParams))
            subject
          end

          it "returns a 200" do
            expect(subject.status).to eq 200
          end

          it "returns a link to the latest pact" do
            expect(JSON.parse(subject.body)["_links"]["pb:latest-pact-version"]["href"]).to eq "http://latest-pact"
          end

          context "with there are no more pacts" do
            let(:latest_pact) { nil }

            it "does not return a link" do
              expect(JSON.parse(subject.body)["_links"]).to_not have_key("pb:latest-pact-version")
            end
          end
        end

        context "when the pact does not exist" do
          let(:pact) { nil }

          it "returns a 404" do
            expect(subject.status).to eq 404
          end
        end
      end
    end
  end
end
