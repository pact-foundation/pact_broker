require 'spec_helper'
require 'pact_broker/api/decorators/version_decorator'

module PactBroker
  module Api
    module Decorators
      describe VersionRepresenter do

        let(:version) do
          ProviderStateBuilder.new
            .create_consumer("Consumer")
            .create_version("1.2.3")
          PactBroker::Repositories::VersionRepository.new.find_by_pacticipant_name_and_number "Consumer", "1.2.3"
        end

        let(:options) { {base_url: 'http://example.org' }}

        subject { JSON.parse VersionRepresenter.new(version).to_json(options), symbolize_names: true }

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1.2.3"
        end

        it "includes the version number" do
          expect(subject[:_links][:self][:name]).to eq "1.2.3"
        end

      end
    end
  end
end
