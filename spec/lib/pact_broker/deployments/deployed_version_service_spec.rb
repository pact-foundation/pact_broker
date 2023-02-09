require "pact_broker/deployments/deployed_version_service"
require "pact_broker/events/subscriber"

module PactBroker
  module Deployments
    describe DeployedVersionService do
      describe ".find_or_create" do
        before do
          td.create_environment("test")
            .create_consumer("foo")
            .create_consumer_version("1")
        end

        let(:version) { td.and_return(:consumer_version) }
        let(:environment) { td.and_return(:environment) }

        context "when the version is already currently deployed" do
          it "returns the existing deployed version object" do
            deployed_version_1 = DeployedVersionService.find_or_create("1234", version, environment, nil)
            deployed_version_2 = DeployedVersionService.find_or_create("4321", version, environment, nil)
            expect(deployed_version_1.uuid).to eq deployed_version_2.uuid
          end
        end

        context "when the version was previously deployed, but there was another version deployed in the meantime" do
          before do
            td.create_consumer_version("2")
          end

          let(:version_1) { PactBroker::Domain::Version.order(:id).first }
          let(:version_2) { PactBroker::Domain::Version.order(:id).last }

          it "returns a new deployed version object" do
            deployed_version_1 = DeployedVersionService.find_or_create("1234", version_1, environment, nil)
            DeployedVersionService.find_or_create("4321", version_2, environment, nil)
            deployed_version_3 = DeployedVersionService.find_or_create("4545", version_1, environment, nil)
            expect(deployed_version_1.uuid).to_not eq deployed_version_3.uuid
          end
        end

        context "with an event listener" do
          before do
            allow(listener).to receive(:deployed_version_created)
          end

          let(:listener) { double("listener") }

          it "broadcasts an event with the deployed_version in the params" do
            expect(listener).to receive(:deployed_version_created) do | params |
              expect(params[:deployed_version].environment).to_not be nil
              expect(params[:deployed_version].version).to_not be nil
              expect(params[:deployed_version].pacticipant).to_not be nil
            end

            PactBroker::Events.subscribe(listener) do
              DeployedVersionService.find_or_create("1234", version, environment, nil)
            end
          end
        end
      end
    end
  end
end
