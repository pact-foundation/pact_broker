require 'spec_helper'
require 'pact_broker/api/decorators/pact_decorator'

module PactBroker

  module Api

    module Decorators

      describe PactDecorator do

        let(:json_content) {
          {
            'consumer' => {'name' => 'Consumer'},
            'provider' => {'name' => 'Provider'},
            'interactions' => [],
            'metadata' => {}
          }.to_json
        }

        let(:base_url) { 'http://example.org' }
        let(:created_at) { Time.new(2014, 3, 4) }
        let(:updated_at) { Time.new(2014, 3, 5) }
        let(:pact) { double('pact', json_content: json_content, created_at: created_at, updated_at: updated_at, consumer: consumer, provider: provider, consumer_version: consumer_version)}
        let(:consumer) { instance_double(PactBroker::Domain::Pacticipant, name: 'Consumer')}
        let(:provider) { instance_double(PactBroker::Domain::Pacticipant, name: 'Provider')}
        let(:consumer_version) { instance_double(PactBroker::Domain::Version, number: '1234')}

        subject { JSON.parse PactDecorator.new(pact).to_json(base_url: base_url), symbolize_names: true}

        describe "#to_json" do

          it "includes the json_content" do
            expect(subject[:consumer]).to eq name: 'Consumer'
          end

          it "includes the createdAt date" do
            expect(subject[:createdAt]).to eq created_at.xmlschema
          end

          it "includes a link to the webhooks for this pact" do
            expect(subject[:_links][:'pact-webhooks'][:href]).to eq "http://example.org/webhooks/provider/Provider/consumer/Consumer"
          end

          it "includes a link to the latest pact" do
            expect(subject[:_links][:'latest-pact'][:title]).to eq "Latest version of the pact between Consumer and Provider"
            expect(subject[:_links][:'latest-pact'][:href]).to eq "http://example.org/pacts/provider/Provider/consumer/Consumer/latest"
          end

          it "includes a link to the pact versions" do
            expect(subject[:_links][:'pact-versions'][:title]).to eq "All versions of the pact between Consumer and Provider"
            expect(subject[:_links][:'pact-versions'][:href]).to eq "http://example.org/pacts/provider/Provider/consumer/Consumer/versions"
          end
        end

      end
    end
  end
end