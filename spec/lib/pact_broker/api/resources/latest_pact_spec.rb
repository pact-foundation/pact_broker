require 'spec_helper'
require 'pact_broker/api/resources/latest_pact'
require 'rack/test'

module PactBroker::Api
  module Resources
    describe LatestPact do
      include Rack::Test::Methods
      describe "GET" do
        context "Accept: text/html" do

          let(:path) { "/pacts/provider/provider_name/consumer/consumer_name/latest/prod" }
          let(:json_content) { 'json_content' }
          let(:pact) { double("pact", json_content: json_content, consumer_version_number: '1') }
          let(:html) { 'html' }
          let(:pact_id_params) { {provider_name: "provider_name", consumer_name: "consumer_name"} }
          let(:html_options) { { base_url: 'http://example.org', badge_url: "http://example.org#{path}/badge.svg" } }
          let(:metadata) { double('metadata') }
          let(:accept) { "text/html" }

          before do
            allow(PactBroker::Pacts::Service).to receive(:find_latest_pact).and_return(pact)
            allow(PactBroker.configuration.html_pact_renderer).to receive(:call).and_return(html)
            allow_any_instance_of(LatestPact).to receive(:ui_base_url).and_return('http://example.org')
          end

          subject { get(path, nil, 'HTTP_ACCEPT' => accept) }

          it "find the pact" do
            expect(PactBroker::Pacts::Service).to receive(:find_latest_pact).with(hash_including(pact_id_params))
            subject
          end

          it "uses the configured HTML renderer" do
            expect(PactBroker.configuration.html_pact_renderer).to receive(:call).with(pact, hash_including(html_options))
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

          context "when Accept is application/hal+json" do
            let(:accept) { "application/hal+json" }
            let(:decorator) { instance_double(PactBroker::Api::Decorators::PactDecorator, to_json: pact_json)}
            let(:pact_json) { { some: 'json' }.to_json }

            before do
              allow(PactBroker::Api::Decorators::PactDecorator).to receive(:new).and_return(decorator)
              allow(PactBroker::Pacts::Metadata).to receive(:build_metadata_for_latest_pact).and_return(metadata)
              allow_any_instance_of(LatestPact).to receive(:encode_webhook_metadata).and_return('encoded metadata')
            end

            it "builds the metadata" do
              expect(PactBroker::Pacts::Metadata).to receive(:build_metadata_for_latest_pact).with(pact, hash_including(tag: 'prod'))
              subject
            end

            it "encodes the metadata" do
              expect_any_instance_of(LatestPact).to receive(:encode_webhook_metadata).with(metadata)
              subject
            end

            it "renders the pact in JSON" do
              expect(decorator).to receive(:to_json).with(user_options: hash_including(metadata: 'encoded metadata'))
              expect(subject.body).to eq pact_json
            end
          end
        end
      end
    end
  end
end
