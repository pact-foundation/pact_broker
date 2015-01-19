require 'spec_helper'
require 'pact_broker/pacts/diff'
require 'pact_broker/pacts/pact_params'

module PactBroker
  module Pacts
    describe Diff do

      describe "#process" do

        let(:pact_content_version_1) do
          hash = load_json_fixture('consumer-provider.json')
          hash['interactions'].first['request']['method'] = 'post'
          hash.to_json
        end
        let(:pact_content_version_2) { load_fixture('consumer-provider.json') }
        let(:pact_content_version_3) { pact_content_version_2 }

        before do
          ProviderStateBuilder.new
            .create_consumer("Consumer")
            .create_provider("Provider")
            .create_consumer_version("1")
            .create_pact(pact_content_version_1)
            .create_consumer_version("2")
            .create_pact(pact_content_version_2)
            .create_consumer_version("3")
            .create_pact(pact_content_version_3)
          allow(DateHelper).to receive(:local_date_in_words).and_return("a date")
        end

        subject { Diff.new.process(pact_params, base_url: 'http://example.org') }

        context "when there is a previous distinct version" do

          let(:pact_params) do
            PactBroker::Pacts::PactParams.new(
              consumer_name: 'Consumer',
              provider_name: 'Provider',
              consumer_version_number: '3'
            )
          end

          it "indicates when the previous change was made" do
            expect(subject).to include "The following changes were made less than a minute ago (a date)"
          end

          it "returns the formatted diff" do
            expect(subject).to include 'interactions'
            expect(subject).to include 'post'
            expect(subject).to include 'get'
          end
        end

        context "when there is not a previous distinct version (this needs to be moved into the resource)" do
          let(:pact_params) do
            PactBroker::Pacts::PactParams.new(
              consumer_name: 'Consumer',
              provider_name: 'Provider',
              consumer_version_number: '1'
            )
          end

          it "returns a message indicating there was no previous distinct version found" do
            expect(subject).to include("No previous distinct version was found")
          end
        end
      end

    end
  end
end
