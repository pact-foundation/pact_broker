require 'pact_broker/contracts/service'

module PactBroker
  module Contracts
    describe Service do
      describe "#publish" do
        let(:contracts_to_publish) do
          ContractsToPublish.from_hash(
            pacticipant_name: "Foo",
            version_number: "1",
            tags: ["a", "b"],
            branch: branch,
            contracts: contracts
          )
        end

        let(:branch) { "main" }
        let(:contracts) { [contract_1] }
        let(:contract_1) do
          ContractToPublish.from_hash(
            provider_name: "Bar",
            content: encoded_contract
          )
        end

        let(:contract) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [] }.to_json }
        let(:encoded_contract) { Base64.strict_encode64(contract) }
        let(:webhook_options) do
          {
            webhook_execution_configuration: webhook_execution_configuration
          }
        end
        let(:webhook_execution_configuration) do
          PactBroker::Webhooks::ExecutionConfiguration.new
            .with_webhook_context(base_url: 'http://example.org')
        end

        subject { Service.publish(contracts_to_publish, webhook_options) }

        it "creates the tags" do
          expect { subject }.to change { PactBroker::Domain::Tag.count }.by 2
        end

        it "sets the version branch" do
          subject
          expect(PactBroker::Domain::Version.order(:id).last.branch).to eq "main"
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

          it "updates the branch (TODO this should add to the branches when branches is updated to be a collection)" do
            expect { subject }.to change { PactBroker::Domain::Version.order(:id).last.branch}.from("feat/x").to("main")
          end
        end
      end
    end
  end
end
