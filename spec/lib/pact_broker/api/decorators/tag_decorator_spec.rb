require 'pact_broker/api/decorators/tag_decorator'
require 'pact_broker/tags/repository'

require 'support/test_data_builder'

module PactBroker

  module Api

    module Decorators

      describe TagDecorator do

        let(:tag) do
          TestDataBuilder.new
            .create_consumer("Consumer")
            .create_version("1.2.3")
            .create_tag("prod")
            .and_return(:tag)
        end

        let(:options) { { user_options: { base_url: 'http://example.org' } } }

        subject { JSON.parse TagDecorator.new(tag).to_json(options), symbolize_names: true }

        it "includes the tag name" do
          expect(subject[:name]).to eq "prod"
        end

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1.2.3/tags/prod"
        end

        it "includes the tag name" do
          expect(subject[:_links][:self][:name]).to eq "prod"
        end

        it "includes a link to the version" do
          expect(subject[:_links][:version][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1.2.3"
        end

        it "includes the version number" do
          expect(subject[:_links][:version][:name]).to eq "1.2.3"
        end

        it "includes a link to the pacticipant" do
          expect(subject[:_links][:pacticipant][:href]).to eq "http://example.org/pacticipants/Consumer"
        end

        it "includes the pacticipant name" do
          expect(subject[:_links][:pacticipant][:name]).to eq "Consumer"
        end

      end
    end
  end
end
