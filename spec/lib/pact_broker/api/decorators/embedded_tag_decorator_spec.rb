require "pact_broker/api/decorators/embedded_tag_decorator"
require "pact_broker/tags/repository"
require "support/test_data_builder"

module PactBroker

  module Api

    module Decorators

      describe EmbeddedTagDecorator do

        let(:tag) do
          td
            .create_consumer("Consumer")
            .create_version("1.2.3")
            .create_tag("prod")
          PactBroker::Tags::Repository.new.find(tag_name: "prod", pacticipant_version_number: "1.2.3", pacticipant_name: "Consumer")
        end

        let(:options) { { user_options: { base_url: "http://example.org" } } }
        let(:json) { EmbeddedTagDecorator.new(tag).to_json(options) }

        subject { JSON.parse json, symbolize_names: true }

        it "includes the tag name" do
          expect(subject[:name]).to eq "prod"
        end

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1.2.3/tags/prod"
        end

        it "includes the tag name" do
          expect(subject[:_links][:self][:name]).to eq "prod"
        end

      end
    end
  end
end
