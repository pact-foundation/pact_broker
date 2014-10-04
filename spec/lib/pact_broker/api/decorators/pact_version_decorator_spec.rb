require 'spec_helper'
require 'pact_broker/api/decorators/pact_version_decorator'

module PactBroker

  module Api

    module Decorators

      describe PactVersionDecorator do

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
        let(:pact) { double('pact', json_content: json_content, created_at: created_at, updated_at: updated_at, consumer: consumer, provider: provider, consumer_version: consumer_version, name: 'pact_name')}
        let(:consumer) { instance_double(PactBroker::Models::Pacticipant, name: 'Consumer')}
        let(:provider) { instance_double(PactBroker::Models::Pacticipant, name: 'Provider')}
        let(:consumer_version) { instance_double(PactBroker::Models::Version, number: '1234', pacticipant: consumer)}
        let(:decorator_context) { DecoratorContext.new(base_url, '') }

        let(:json) { PactVersionDecorator.new(pact).to_json(decorator_context) }

        subject { JSON.parse(json, symbolize_names: true) }

        it "includes a link to the pact" do
          expect(subject[:_links][:self][:href]).to eq 'http://example.org/pacts/provider/Provider/consumer/Consumer/version/1234'
        end

        it "includes the consumer version number" do
          expect(subject[:_embedded][:consumerVersion][:number]).to eq "1234"
        end

        it "includes a link to the version" do
          expect(subject[:_embedded][:consumerVersion][:_links][:self][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1234"
        end

        it "includes timestamps" do
          expect(subject[:createdAt]).to_not be_nil
          expect(subject[:updatedAt]).to_not be_nil
        end

      end
    end
  end
end
