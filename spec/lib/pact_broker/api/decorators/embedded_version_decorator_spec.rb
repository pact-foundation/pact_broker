require "pact_broker/api/decorators/embedded_version_decorator"

module PactBroker
  module Api
    module Decorators
      describe EmbeddedVersionDecorator do

        let(:version) do
          TestDataBuilder.new
            .create_consumer("Consumer")
            .create_version("1.2.3")
          PactBroker::Versions::Repository.new.find_by_pacticipant_name_and_number "Consumer", "1.2.3"
        end

        let(:options) { { user_options: { base_url: "http://example.org" } } }

        subject { JSON.parse EmbeddedVersionDecorator.new(version).to_json(options), symbolize_names: true }

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

      end
    end
  end
end
