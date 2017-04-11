require 'spec_helper'
require 'pact_broker/api/decorators/version_decorator'

module PactBroker
  module Api
    module Decorators
      describe VersionDecorator do

        let(:version) do
          ProviderStateBuilder.new
            .create_consumer("Consumer")
            .create_consumer_version("1.2.3")
            .create_consumer_version_tag("prod")
          PactBroker::Versions::Repository.new.find_by_pacticipant_name_and_number "Consumer", "1.2.3"
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
          expect(subject[:_links][:pacticipant]).to eq title: "Pacticipant", name: "Consumer", href: "http://example.org/pacticipants/Consumer"
        end

        it "includes a list of the tags" do
          expect(subject[:_embedded][:tags]).to be_instance_of(Array)
          expect(subject[:_embedded][:tags].first[:name]).to eq "prod"
        end

        it "includes a link to the latest verifications for the pacts for this version" do
          expect(subject[:_links][:'pb:latest-verifications'][:href]).to match(%r{http://.*/verifications/latest})
        end

      end
    end
  end
end
