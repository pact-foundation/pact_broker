require "spec_helper"
require "pact_broker/api/decorators/pacticipant_collection_decorator"
require "pact_broker/domain/pacticipant"

module PactBroker
  module Api
    module Decorators
      describe PacticipantCollectionDecorator do
        let(:options) { {user_options: {base_url: "http://example.org"} } }
        let(:pacticipants) { [] }
        let(:json) { PacticipantCollectionDecorator.new(pacticipants).to_json(**options) }

        subject { JSON.parse json, symbolize_names: true }

        it "includes a link to find pacticipants by label" do
          expect(subject[:_links][:'pb:pacticipants-with-label'][:href]).to match %r{http://.*label/{label}}
        end

        context "with no pacticipants" do
          it "doesn't blow up" do
            subject
          end
        end

        context "with pacticipants" do
          let(:pacticipant) { PactBroker::Domain::Pacticipant.new(name: "Name", created_at: DateTime.new, updated_at: DateTime.new)}
          let(:pacticipants) { [pacticipant] }

          it "displays a list of pacticipants" do
            expect(subject[:_embedded][:pacticipants]).to be_instance_of(Array)
            expect(subject[:_embedded][:pacticipants].size).to eq 1
          end
        end
      end

      describe DeprecatedPacticipantCollectionDecorator do
        let(:options) { { user_options: { base_url: base_url } } }
        let(:pacticipant) { PactBroker::Domain::Pacticipant.new(name: "Name", created_at: DateTime.new, updated_at: DateTime.new)}
        let(:pacticipants) { [pacticipant] }
        let(:base_url) { "http://example.org" }
        let(:json) { DeprecatedPacticipantCollectionDecorator.new(pacticipants).to_json(**options) }

        subject { JSON.parse(json, symbolize_names: true) }

        it "includes the pacticipants under the _embedded key" do
          expect(subject[:_embedded][:pacticipants]).to be_instance_of(Array)
        end

        it "includes the pacticipants under the pacticipants key" do
          expect(subject[:pacticipants]).to be_instance_of(Array)
        end

        it "includes a deprecation warning in the pacticipants links" do
          expect(subject[:_links][:pacticipants].first[:name]).to include "DEPRECATED"
        end

        it "includes a deprecation warning in the non-embedded pacticipant title" do
          expect(subject[:pacticipants].first[:title]).to include "DEPRECATED"
        end

        it "passes in the options correctly (Representable does inconsistent things with the args of to_json and to_hash)" do
          allow_any_instance_of(PactBroker::Api::PactBrokerUrls). to receive(:pacticipants_url) do | _instance, actual_base_url |
            @actual_base_url = actual_base_url
            ""
          end
          subject
          expect(@actual_base_url).to eq base_url
        end
      end
    end
  end
end
