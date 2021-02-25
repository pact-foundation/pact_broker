require 'pact_broker/ui/view_models/matrix_deployed_version'

module PactBroker
  module UI
    module ViewDomain
      describe MatrixDeployedVersion do
        before do
          allow(subject).to receive(:deployed_version_url).and_return("http://deployed_version")
          allow(subject).to receive(:hal_browser_url) do | url |
            "http://halbrowser#" + url
          end
        end
        subject(:matrix_deployed_version) { MatrixDeployedVersion.new(deployed_version) }
        let(:deployed_version) do
          instance_double("PactBroker::Deployments::DeployedVersion",
            environment: environment,
            created_at: created_at
          )
        end
        let(:created_at) { (Date.today - 400).to_datetime }
        let(:environment) { instance_double("PactBroker::Deployments::Environment", name: "test", display_name: "Test") }

        its(:environment_name) { is_expected.to eq "test" }
        its(:tooltip) { is_expected.to eq "Currently deployed to Test (about 1 year ago)" }
        its(:url) { is_expected.to eq "http://halbrowser#http://deployed_version" }
      end
    end
  end
end
