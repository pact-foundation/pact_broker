require 'spec_helper'
require 'pact_broker/pacts/service'
require 'pact_broker/pacts/pact_params'


module PactBroker

  module Pacts
    describe Service do
      let(:td) { TestDataBuilder.new }

      describe "create_or_update_pact" do
        include_context "stubbed repositories"

        before do
          allow(described_class).to receive(:webhook_service).and_return(webhook_service)
          allow(pacticipant_repository).to receive(:find_by_name_or_create).with(params[:consumer_name]).and_return(consumer)
          allow(pacticipant_repository).to receive(:find_by_name_or_create).with(params[:provider_name]).and_return(provider)
          allow(version_repository).to receive(:find_by_pacticipant_id_and_number_or_create).and_return(version)
          allow(pact_repository).to receive(:find_by_version_and_provider).and_return(existing_pact)
          allow(pact_repository).to receive(:create).and_return(new_pact)
          allow(pact_repository).to receive(:update).and_return(new_pact)
          allow(pact_repository).to receive(:find_previous_pacts).and_return(previous_pacts)
          allow(webhook_service).to receive(:trigger_webhooks)
        end

        let(:webhook_service) { class_double("PactBroker::Webhooks::Service").as_stubbed_const }
        let(:consumer) { double('consumer', id: 1) }
        let(:provider) { double('provider', id: 2) }
        let(:version) { double('version', id: 3, pacticipant_id: 1) }
        let(:existing_pact) { nil }
        let(:new_pact) { double('new_pact', json_content: json_content) }
        let(:json_content) { { the: "contract" }.to_json }
        let(:json_content_with_ids) { { the: "contract with ids" }.to_json }
        let(:previous_pacts) { [] }
        let(:params) do
          {
            consumer_name: "Foo",
            provider_name: "Bar",
            consumer_version_number: "1",
            json_content: json_content
          }
        end
        let(:content) { double('content') }
        let(:content_with_interaction_ids) { double('content_with_interaction_ids', to_json: json_content_with_ids) }

        before do
          allow(Content).to receive(:from_json).and_return(content)
          allow(content).to receive(:with_ids).and_return(content_with_interaction_ids)
          allow(PactBroker::Pacts::GenerateSha).to receive(:call).and_call_original
        end

        subject { Service.create_or_update_pact(params) }


        context "when no pact exists with the same params" do
          it "creates the sha before adding the interaction ids" do
            expect(PactBroker::Pacts::GenerateSha).to receive(:call).ordered
            expect(content).to receive(:with_ids).ordered
            subject
          end

          it "saves the pact interactions/messages with ids added to them" do
            expect(pact_repository).to receive(:create).with hash_including(json_content: json_content_with_ids)
            subject
          end

          it "triggers webhooks for contract publications" do
            expect(webhook_service).to receive(:trigger_webhooks).with(new_pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED)
            subject
          end
        end

        context "when a pact exists with the same params" do
          let(:existing_pact) { double('existing_pact', id: 4, json_content: { the: "contract" }.to_json) }

          it "creates the sha before adding the interaction ids" do
            expect(PactBroker::Pacts::GenerateSha).to receive(:call).ordered
            expect(content).to receive(:with_ids).ordered
            subject
          end

          it "saves the pact interactions/messages with ids added to them" do
            expect(pact_repository).to receive(:update).with(anything, hash_including(json_content: json_content_with_ids))
            subject
          end

          it "triggers webhooks for contract publications" do
            expect(webhook_service).to receive(:trigger_webhooks).with(new_pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED)
            subject
          end
        end
      end

      describe "find_distinct_pacts_between" do
        let(:pact_1) { double('pact 1', json_content: 'content 1')}
        let(:pact_2) { double('pact 2', json_content: 'content 2')}
        let(:pact_3) { double('pact 3', json_content: 'content 2')}
        let(:pact_4) { double('pact 4', json_content: 'content 3')}

        let(:all_pacts) { [pact_4, pact_3, pact_2, pact_1]}

        before do
          allow_any_instance_of(Pacts::Repository).to receive(:find_all_pact_versions_between).and_return(all_pacts)
        end

        subject { Service.find_distinct_pacts_between 'consumer', :and => 'provider' }

        it "returns the distinct pacts" do
          expect(subject).to eq [pact_4, pact_2, pact_1]
        end
      end

      describe "#pact_is_new_or_pact_has_changed_since_previous_version?" do
        let(:json_content) { { 'some' => 'json'}.to_json }
        let(:pact) { instance_double(PactBroker::Domain::Pact, json_content: json_content)}

        subject { Service.pact_is_new_or_pact_has_changed_since_previous_version? pact }

        context "when consumer version is untagged" do
          before do
            allow(pact).to receive(:consumer_version_tag_names).and_return([]);
            allow_any_instance_of(Pacts::Repository).to receive(:find_previous_pact).with(pact, :untagged).and_return(previous_pact)
          end

          context "when a previous pact is found" do
            let(:previous_pact) { instance_double(PactBroker::Domain::Pact, json_content: previous_json_content)}
            let(:previous_json_content) { {'some' => 'json'}.to_json }

            context "when the json_content is the same" do
              it "returns false" do
                expect(subject).to be_falsey
              end
            end

            context "when the json_content is not the same" do
              let(:previous_json_content) { {'some-other' => 'json'}.to_json }
              it "returns truthy" do
                expect(subject).to be_truthy
              end
            end
          end

          context "when a previous pact is not found" do
            let(:previous_pact) { nil }

            it "returns true" do
              expect(subject).to be_truthy
            end
          end
        end

        context "when consumer version has two tags" do
          before do
            allow(pact).to receive(:consumer_version_tag_names).and_return(['tag_1', 'tag_2']);
            allow_any_instance_of(Pacts::Repository).to receive(:find_previous_pact).with(pact, 'tag_1').and_return(previous_pact_tag_1)
            allow_any_instance_of(Pacts::Repository).to receive(:find_previous_pact).with(pact, 'tag_2').and_return(previous_pact_tag_2)
          end

          context "when a previous pact is found for both tags" do
            let(:previous_pact_tag_1) { instance_double(PactBroker::Domain::Pact, json_content: previous_json_content_tag_1)}
            let(:previous_json_content_tag_1) { {'some' => 'json'}.to_json }

            let(:previous_pact_tag_2) { instance_double(PactBroker::Domain::Pact, json_content: previous_json_content_tag_2)}
            let(:previous_json_content_tag_2) { {'some' => 'json'}.to_json }

            context "when the json_content of both previous pacts and new pact is the same" do
              it "returns false" do
                expect(subject).to be_falsey
              end
            end

            context "when the json_content of first previous pact is not the same" do
              let(:previous_json_content_tag_1) { {'some-other' => 'json'}.to_json }
              it "returns truthy" do
                expect(subject).to be_truthy
              end
            end

            context "when the json_content of second previous pact not the same" do
              let(:previous_json_content_tag_2) { {'some-other' => 'json'}.to_json }
              it "returns truthy" do
                expect(subject).to be_truthy
              end
            end
          end

          context "when no previous pacts are found" do
            let(:previous_pact_tag_1) { nil }
            let(:previous_pact_tag_2) { nil }

            it "returns true" do
              expect(subject).to be_truthy
            end
          end
        end
      end

      describe "delete" do
        before do
          td.create_pact_with_hierarchy
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_deprecated_webhook_execution
            .revise_pact
        end

        let(:params) do
          {
            consumer_name: td.consumer.name,
            provider_name: td.provider.name,
            consumer_version_number: td.consumer_version.number
          }
        end

        subject { Service.delete PactParams.new(PactBroker::Pacts::PactParams.new(params)) }

        it "deletes the pact" do
          expect { subject }.to change {
            Pacts::PactPublication.where(id: td.pact.id ).count
          }.by(-1)
        end
      end
    end
  end
end
