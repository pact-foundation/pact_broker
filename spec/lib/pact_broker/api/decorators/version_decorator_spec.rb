require 'spec_helper'
require 'pact_broker/api/decorators/version_decorator'

module PactBroker
  module Api
    module Decorators
      describe VersionDecorator do

        let(:version) do
          TestDataBuilder.new
            .create_consumer("Consumer")
            .create_provider("providerA")
            .create_consumer_version("1.2.3")
            .create_consumer_version_tag("feat-x")
            .create_consumer_version_environment("prod")
            .create_pact
            .create_provider("ProviderB")
            .create_pact
            .and_return(:consumer_version)
        end

        let(:options) { { user_options: { base_url: 'http://example.org' } } }

        subject { JSON.parse VersionDecorator.new(version).to_json(options), symbolize_names: true }

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1.2.3"
        end

        it "includes the version number in the link" do
          expect(subject[:_links][:self][:name]).to eq "1.2.3"
        end

        it "includes its title in the link" do
          expect(subject[:_links][:self][:title]).to eq "Version"
        end

        it "includes the version number" do
          expect(subject[:number]).to eq "1.2.3"
        end

        it "includes a link to the pacticipant" do
          expect(subject[:_links][:'pb:pacticipant']).to eq title: "Pacticipant", name: "Consumer", href: "http://example.org/pacticipants/Consumer"
        end

        it "includes a list of the tags" do
          expect(subject[:_embedded][:tags]).to be_instance_of(Array)
          expect(subject[:_embedded][:tags].first[:name]).to eq "feat-x"
        end

        it "includes a list of the environments" do
          expect(subject[:_embedded][:environments]).to be_instance_of(Array)
          expect(subject[:_embedded][:environments].first[:name]).to eq "prod"
        end

        it "includes a list of sorted pacts" do
          expect(subject[:_links][:'pb:pact-versions']).to be_instance_of(Array)
          expect(subject[:_links][:'pb:pact-versions'].first[:href]).to include ("1.2.3")
          expect(subject[:_links][:'pb:pact-versions'].first[:name]).to include ("Pact between")
          expect(subject[:_links][:'pb:pact-versions'].first[:name]).to include ("providerA")
          expect(subject[:_links][:'pb:pact-versions'].last[:name]).to include ("ProviderB")
        end

        it "includes a link to the latest verification results for the pacts for this version" do
          expect(subject[:_links][:'pb:latest-verification-results-where-pacticipant-is-consumer'][:href]).to match(%r{http://.*/verification-results/.*/latest})
        end
      end
    end
  end
end
