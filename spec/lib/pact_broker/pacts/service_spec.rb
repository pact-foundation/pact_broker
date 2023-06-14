require "pact_broker/pacts/service"
require "pact_broker/pacts/pact_params"
require "pact_broker/webhooks/execution_configuration"

module PactBroker
  module Pacts
    describe Service do
      describe "create_or_update_pact" do
        include_context "stubbed repositories"

        before do
          allow(pacticipant_repository).to receive(:find_by_name_or_create).with(params[:consumer_name]).and_return(consumer)
          allow(pacticipant_repository).to receive(:find_by_name_or_create).with(params[:provider_name]).and_return(provider)
          allow(version_repository).to receive(:find_by_pacticipant_id_and_number_or_create).and_return(version)
          allow(pact_repository).to receive(:find_by_version_and_provider).and_return(existing_pact)
          allow(pact_repository).to receive(:create).and_return(new_pact)
          allow(pact_repository).to receive(:update).and_return(new_pact)
          allow(pact_repository).to receive(:find_previous_pacts).and_return(previous_pacts)
        end

        let(:consumer) { double("consumer", id: 1) }
        let(:provider) { double("provider", id: 2) }
        let(:version) { double("version", id: 3, pacticipant_id: 1) }
        let(:existing_pact) { nil }
        let(:new_pact) { double("new_pact", consumer_version_tag_names: %w[dev], json_content: json_content, pact_version_sha: "1", consumer_name: "Foo", consumer_version_number: "2") }
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
        let(:content) { double("content") }
        let(:content_with_interaction_ids) { double("content_with_interaction_ids", to_json: json_content_with_ids) }
        let(:expected_event_context) { { consumer_version_tags: ["dev"] } }

        before do
          allow(Content).to receive(:from_json).and_return(content)
          allow(content).to receive(:with_ids).and_return(content_with_interaction_ids)
          allow(PactBroker::Pacts::GenerateSha).to receive(:call).and_call_original
          allow(Service).to receive(:broadcast)
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

          # TODO test all this contract_content_changed logic properly!
          context "when the latest pact for one of the tags has a different pact_version_sha" do
            before do
              allow(pact_repository).to receive(:find_previous_pacts).and_return(previous_pacts_by_tag)
            end

            let(:previous_dev_pact_version_sha) { "2" }
            let(:previous_pacts_by_tag) do
              {
                dev: double("previous pact", pact_version_sha: previous_dev_pact_version_sha)
              }
            end

            it "broadcasts the contract_published event" do
              expect(Service).to receive(:broadcast).with(
                :contract_published,
                  {
                    pact: new_pact,
                    event_context: { consumer_version_tags: %w[dev] }
                  }
              )
              subject
            end

            it "broadcasts the contract_content_changed event" do
              expect(Service).to receive(:broadcast).with(
                :contract_content_changed,
                  {
                    pact: new_pact,
                    event_comment: "pact content has changed since the last consumer version tagged with dev",
                    event_context: { consumer_version_tags: %w[dev] }
                  }
              )
              subject
            end
          end

          context "when the new pact has not changed content or tags since the previous version with the same tags" do
            before do
              allow(pact_repository).to receive(:find_previous_pacts).and_return(previous_pacts_by_tag)
            end

            let(:previous_dev_pact_version_sha) { "1" }
            let(:previous_pacts_by_tag) do
              {
                dev: double("previous pact", pact_version_sha: previous_dev_pact_version_sha)
              }
            end

            it "broadcasts the contract_published event" do
              expect(Service).to receive(:broadcast).with(
                :contract_published,
                  {
                    pact: new_pact,
                    event_comment: "pact content is the same as previous version with tag dev and no new tags were applied",
                    event_context: { consumer_version_tags: %w[dev] }
                  }
              )
              subject
            end
          end
        end

        context "when a pact exists with the same params" do
          let(:existing_pact) do
            double("existing_pact",
              id: 4,
              consumer_version_tag_names: %[dev],
              json_content: { the: "contract" }.to_json,
              pact_version_sha: pact_version_sha
            )
          end
          let(:pact_version_sha) { "1" }

          let(:expected_event_context) { { consumer_version_tags: ["dev"] } }

          it "creates the sha before adding the interaction ids" do
            expect(PactBroker::Pacts::GenerateSha).to receive(:call).ordered
            expect(content).to receive(:with_ids).ordered
            subject
          end

          it "saves the pact interactions/messages with ids added to them" do
            expect(pact_repository).to receive(:update).with(anything, hash_including(json_content: json_content_with_ids))
            subject
          end

          it "broadcasts the contract_published event" do
            expect(Service).to receive(:broadcast).with(:contract_published, { pact: new_pact, event_context: { consumer_version_tags: %w[dev] } })
            subject
          end

          context "when the pact_version_sha is different" do
            let(:pact_version_sha) { "2" }

            it "broadcasts the contract_content_changed event" do
              expect(Service).to receive(:broadcast).with(
                :contract_content_changed,
                  {
                    pact: new_pact,
                    event_comment: "pact content modified since previous publication for Foo version 2",
                    event_context: { consumer_version_tags: %w[dev] }
                  }
              )
              subject
            end
          end

          context "when the pact_version_sha is the same" do
            it "broadcasts the contract_content_unchanged event" do
              expect(Service).to receive(:broadcast).with(
                :contract_content_unchanged,
                  {
                    pact: new_pact,
                    event_comment: "pact content was unchanged",
                    event_context: { consumer_version_tags: %w[dev] }
                  }
              )
              subject
            end
          end
        end
      end

      describe "find_distinct_pacts_between" do
        let(:pact_1) { double("pact 1", json_content: "content 1")}
        let(:pact_2) { double("pact 2", json_content: "content 2")}
        let(:pact_3) { double("pact 3", json_content: "content 2")}
        let(:pact_4) { double("pact 4", json_content: "content 3")}

        let(:all_pacts) { [pact_4, pact_3, pact_2, pact_1]}

        before do
          allow_any_instance_of(Pacts::Repository).to receive(:find_all_pact_versions_between).and_return(all_pacts)
        end

        subject { Service.find_distinct_pacts_between "consumer", :and => "provider" }

        it "returns the distinct pacts" do
          expect(subject).to eq [pact_4, pact_2, pact_1]
        end
      end

      describe "delete" do
        before do
          td.create_pact_with_hierarchy
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
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

      describe "find_for_verification integration test" do
        before do
          td.create_provider("Bar")
            .create_provider_version
            .create_provider_version_tag("master")
            .add_minute
            .create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("feat-1", comment: "latest for feat-1")
            .create_consumer_version("2")
            .create_pact(comment: "overall latest")
            .create_consumer_version("3")
        end

        let(:options) { { } }

        subject { Service.find_for_verification("Bar", nil, ["master"], Selectors.new, options) }


        context "when the consumer version tags are empty" do
          it "returns the latest overall pact for the consumer" do
            expect(subject.first.consumer_version_number).to eq "2"
            expect(subject.first.wip).to be false
          end
        end

        context "when include_wip_pacts_since is not specified" do
          it "does not include the WIP pacts" do
            expect(subject.size).to eq 1
          end
        end

        context "when WIP pacts are included" do
          let(:options) do
            {
              include_wip_pacts_since: (Date.today - 1).to_datetime
            }
          end

          it "returns the WIP pacts as well as the specified pacts" do
            expect(subject.size).to eq 2
            expect(subject.last.consumer_version_number).to eq "1"
            expect(subject.last.wip).to be true
          end

          context "when the WIP pact has the same content as a specified pact" do
            before do
              td.create_pact_with_hierarchy("Blah", "1", "Wiffle")
                .create_consumer_version_tag("feat-1", comment: "latest for feat-1")
                .create_consumer_version("2")
                .republish_same_pact(comment: "overall latest")
            end

            subject { Service.find_for_verification("Wiffle", "main", ["master"], Selectors.new, options) }

            it "is not included" do
              expect(subject.size).to eq 1
            end
          end
        end
      end

      describe "find_for_verification_publication integration test" do
        before do
          json_content = { interactions: [] }.to_json
          td.create_pact_with_hierarchy("Foo", "1", "Bar", json_content)
            .create_pact_with_hierarchy("Foo", "2", "Bar", json_content)
        end

        let(:consumer_version_selector_hashes) do
          [
            { tag: "foo", latest: true, consumer_version_number: "1"},
            { tag: "bar", latest: true, consumer_version_number: "1"},
            { branch: "beep", latest: true, consumer_version_number: "2"}
          ]
        end

        let(:pact_params) do
          PactParams.new(
            consumer_name: "Foo",
            provider_name: "Bar",
            pact_version_sha: td.and_return(:pact).pact_version_sha
          )
        end

        subject { Service.find_for_verification_publication(pact_params, consumer_version_selector_hashes) }

        it "deduplicates the pacts by consumer version number" do
          expect(subject.size).to eq 2
        end

        it "sets the selectors" do
          expect(subject.first.selectors.size).to eq 2
          expect(subject.first.selectors.first).to have_attributes(latest: true, tag: "bar")
          expect(subject.first.selectors.first.consumer_version).to have_attributes(number: "1")

          expect(subject.first.selectors.last).to have_attributes(latest: true, tag: "foo")
          expect(subject.first.selectors.last.consumer_version).to have_attributes(number: "1")

          expect(subject.last.selectors.size).to eq 1
          expect(subject.last.selectors.first).to have_attributes(latest: true, branch: "beep")
          expect(subject.last.selectors.last.consumer_version).to have_attributes(number: "2")
        end

        context "when there are no consumer version selectors" do
          let(:consumer_version_selector_hashes) { nil }

          it "returns the latest pact for the sha" do
            expect(subject.size).to eq 1
            expect(subject.first.consumer_version_number).to eq "2"
          end
        end

        context "when the consumer version selectors is empty" do
          let(:consumer_version_selector_hashes) { [] }

          it "returns the latest pact for the sha" do
            expect(subject.size).to eq 1
            expect(subject.first.consumer_version_number).to eq "2"
          end
        end
      end
    end
  end
end
