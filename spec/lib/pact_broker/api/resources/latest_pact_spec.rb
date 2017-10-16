require 'spec_helper'
require 'pact_broker/api/resources/latest_pact'
require 'rack/test'

module PactBroker::Api

  module Resources

    describe LatestPact do

      include Rack::Test::Methods

      let(:app) { PactBroker::API }

      describe "GET" do

        context "Accept: text/html" do

          let(:path) { "/pacts/provider/provider_name/consumer/consumer_name/latest" }
          let(:json_content) { 'json_content' }
          let(:pact) { double("pact", json_content: json_content)}
          let(:html) { 'html' }
          let(:pact_id_params) { {provider_name: "provider_name", consumer_name: "consumer_name"} }
          let(:html_options) { { base_url: 'http://example.org', badge_url: "http://example.org#{path}/badge.svg" } }

          before do
            allow(PactBroker::Pacts::Service).to receive(:find_latest_pact).and_return(pact)
            allow(PactBroker.configuration.html_pact_renderer).to receive(:call).and_return(html)
          end

          subject { get path ,{}, {'HTTP_ACCEPT' => "text/html"} }

          it "find the pact" do
            expect(PactBroker::Pacts::Service).to receive(:find_latest_pact).with(hash_including(pact_id_params))
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
            expect(last_response.headers['Content-Type']).to eq 'text/html;charset=utf-8'
          end

        end
      end

    end
  end

end
