require "pact_broker/deployments/environment"
require "pact_broker/deployments/deployed_version"

module PactBroker
  module Deployments
    describe Environment do
      describe "delete" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("1")
            .create_environment("test")
            .create_deployed_version_for_consumer_version
            .create_environment("prod")
            .create_deployed_version_for_consumer_version
        end

        it "deletes the associated deployed versions when deleting individual environments" do
          expect { Environment.find(name: "test").delete }.to change { DeployedVersion.count }.by(-1)
        end

        it "deletes the associated deployed versions when deleting an environment dataset" do
          expect { Environment.where(name: "test").delete }.to change { DeployedVersion.count }.by(-1)
        end
      end
    end
  end
end
