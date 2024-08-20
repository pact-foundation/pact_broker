require "pact_broker/contracts/service"

module PactBroker
  module Contracts
    describe Service do
      describe "#publish" do
        let(:contracts_to_publish) do
          ContractsToPublish.from_hash(
            pacticipant_name: "Foo",
            pacticipant_version_number: "1",
            tags: ["a", "b"],
            branch: branch,
            contracts: contracts
          )
        end

        let(:on_conflict) { "overwrite" }
        let(:branch) { "main" }
        let(:contracts) { [contract_1] }
        let(:contract_1) do
          ContractToPublish.new(
            consumer_name: "Foo",
            provider_name: "Bar",
            decoded_content: decoded_contract,
            pact_version_sha: PactBroker::Pacts::GenerateSha.call(decoded_contract),
            specification: "pact",
            on_conflict: on_conflict
          )
        end

        let(:contract_hash) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [{a: "b"}] } }
        let(:decoded_contract) { contract_hash.to_json }
        let(:base_url) { "http://example.org" }

        subject { Service.publish(contracts_to_publish, base_url: base_url) }

        it "creates the tags" do
          expect { subject }.to change { PactBroker::Domain::Tag.count }.by 2
        end

        it "sets the version branch" do
          subject
          expect(PactBroker::Domain::Version.order(:id).last.branch_names).to include "main"
        end

        it "returns a results object" do
          expect(subject.contracts.first).to be_a(PactBroker::Domain::Pact)
        end

        context "when the pact does not already exist" do
          context "when the write mode is overwrite" do
            it "returns an info message" do
              expect(subject.notices.find{ |log| log.type == "success" && log.text.include?(" published ") }).to_not be nil
            end
          end

          context "when the write mode is merge" do
            let(:on_conflict) { "merge" }

            it "returns an info message" do
              expect(subject.notices.find{ |log| log.type == "success" && log.text.include?(" published ") }).to_not be nil
            end
          end

          context "when no branch is specified but tags are" do
            before do
              allow(PactBroker.configuration).to receive(:use_first_tag_as_branch).and_return(true)
            end

            let(:contracts_to_publish) do
              ContractsToPublish.from_hash(
                pacticipant_name: "Foo",
                pacticipant_version_number: "1",
                tags: ["a", "b"],
                branch: nil,
                contracts: contracts
              )
            end

            it "uses the first tag as the branch" do
              subject
              expect(PactBroker::Domain::Version.order(:id).last.branch_versions.collect(&:branch_name)).to eq ["a"]
            end
          end
        end

        context "when the pact already exists" do
          before do
            td.create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version("1", branch: "feat/x", tag_names: ["z"])
              .create_pact
          end

          it "adds the tags to the existing version" do
            expect { subject }.to change { PactBroker::Domain::Version.order(:id).last.tags.count}.from(1).to(3)
          end

          it "adds the branch to the existing version" do
            expect { subject }.to change { PactBroker::Domain::Version.order(:id).last.branch_versions.collect(&:branch_name)}.from(["feat/x"]).to(["feat/x", "main"])
          end

          context "when the write mode is overwrite" do
            context "when the content is different" do
              it "returns a warning message" do
                expect(subject.notices.find{ |log| log.type == "warning" && log.text.include?("changed content") }).to_not be nil
              end
            end

            context "when the content is the same" do
              let(:decoded_contract) { PactBroker::Pacts::PactVersion.last.content }

              it "returns an info message" do
                expect(subject.notices.find{ |log| log.type == "success" && log.text.include?("republished") }).to_not be nil
              end
            end
          end

          context "when the write mode is merge" do
            let(:on_conflict) { "merge" }

            it "returns an info message" do
              expect(subject.notices.find{ |log| log.type == "success" && log.text.include?("merged") }).to_not be nil
            end
          end
        end
      end

      describe "#conflict_errors" do
        before do
          allow(Service).to receive(:pacticipant_service).and_return(pacticipant_service)
          allow(pacticipant_service).to receive(:messages_for_potential_duplicate_pacticipants).and_return(duplicate_pacticipant_messages)
          allow(PactBroker.configuration).to receive(:check_for_potential_duplicate_pacticipant_names).and_return(true)
        end

        let(:pacticipant_service) { class_double("PactBroker::Pacticipants::Service").as_stubbed_const }
        let(:duplicate_pacticipant_messages) { [] }

        let(:contracts_to_publish) do
          ContractsToPublish.from_hash(
            pacticipant_name: "Foo",
            pacticipant_version_number: "1",
            tags: ["a", "b"],
            branch: branch,
            contracts: contracts
          )
        end

        let(:on_conflict) { "overwrite" }
        let(:branch) { "main" }
        let(:contracts) { [contract_1] }
        let(:contract_1) do
          ContractToPublish.new(
            consumer_name: "Foo",
            provider_name: "Bar",
            decoded_content: decoded_contract,
            specification: "pact",
            on_conflict: on_conflict,
            pact_version_sha: new_pact_version_sha
          )
        end

        let(:contract_hash) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [{a: "b"}] } }
        let(:decoded_contract) { contract_hash.to_json }
        let(:new_pact_version_sha) { PactBroker::Pacts::GenerateSha.call(decoded_contract) }

        subject { Service.conflict_notices(contracts_to_publish, base_url: "base_url") }

        context "when a pact already exists" do
          before do
            allow(PactBroker.configuration).to receive(:allow_dangerous_contract_modification).and_return(allow_dangerous_contract_modification)
            td.create_pact_with_hierarchy("Foo", "1", "Bar", existing_json_content)
          end

          let(:existing_json_content) { td.random_json_content("Foo", "Bar") }

          context "when allow_dangerous_contract_modification=false and the pact content is different" do
            let(:allow_dangerous_contract_modification) { false }

            it "returns errors" do
              expect(subject).to_not be_empty
            end
          end

          context "when allow_dangerous_contract_modification=false and the pact content is the same" do
            let(:allow_dangerous_contract_modification) { false }
            let(:existing_json_content) { decoded_contract }

            it { is_expected.to be_empty }
          end

          context "when allow_dangerous_contract_modification=true and the pact content is different" do
            let(:allow_dangerous_contract_modification) { true }

            it { is_expected.to be_empty }
          end
        end

        context "when no pacts exist" do
          it { is_expected.to be_empty }
        end

        it "checks if there are potential duplicate pacticipants" do
          expect(pacticipant_service).to receive(:messages_for_potential_duplicate_pacticipants).with(["Foo", "Bar"], "base_url")
          subject
        end

        context "when there are potential duplicate pacticipants" do
          let(:duplicate_pacticipant_messages) { ["some message" ] }

          it "returns the messages as error notices" do
            expect(subject).to contain_exactly(have_attributes(type: "error", text: "some message"))
          end
        end
      end
    end
  end
end
