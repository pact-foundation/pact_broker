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
          ContractToPublish.from_hash(
            consumer_name: "Foo",
            provider_name: "Bar",
            decoded_content: decoded_contract,
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
          expect(PactBroker::Domain::Version.order(:id).last.branch).to eq "main"
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
    end
  end
end
