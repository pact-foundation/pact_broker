require 'spec_helper'
require 'pact_broker/api/decorators/versions_decorator'
require 'pact_broker/domain/version'

module PactBroker

  module Api

    module Decorators

      describe VersionsDecorator do

        let(:options) { {base_url: 'http://example.org', pacticipant_name: "Consumer" }}

        subject { JSON.parse VersionsDecorator.new(versions).to_json(user_options: options), symbolize_names: true }

        context "with no versions" do
          let(:versions) { [] }

          it "doesn't blow up" do
            subject
          end
        end

        context "with versions" do
          let(:version) do
            ProviderStateBuilder.new
              .create_consumer("Consumer")
              .create_consumer_version("1.2.3")
              .create_consumer_version_tag("prod")
            PactBroker::Versions::Repository.new.find_by_pacticipant_name_and_number "Consumer", "1.2.3"
          end
          let(:versions) { [version] }

          it "displays a list of versions" do
            expect(subject[:_embedded][:versions]).to be_instance_of(Array)
            expect(subject[:_embedded][:versions].size).to eq 1
          end
        end

      end
    end
  end
end
