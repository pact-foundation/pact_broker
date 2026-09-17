require "pact_broker/ui/view_models/matrix_released_version"

module PactBroker
  module UI
    module ViewModels
      describe MatrixReleasedVersion do
        before do
          allow(subject).to receive(:released_version_url) do | released_version, base_url |
            base_url ? "#{base_url}/released_version" : "/released_version"
          end
        end

        subject(:matrix_released_version) { MatrixReleasedVersion.new(released_version, base_url) }
        let(:released_version) do
          instance_double("PactBroker::Deployments::ReleasedVersion",
            environment: environment,
            created_at: created_at
          )
        end
        let(:created_at) { DateTime.now - 1 }
        let(:environment) { instance_double("PactBroker::Deployments::Environment", name: "test", display_name: "Test") }
        let(:base_url) { nil }

        its(:environment_name) { is_expected.to eq "test" }
        its(:tooltip) { is_expected.to eq "Currently released and supported in Test (1 day ago)" }

        describe "#url" do
          context "without base_url" do
            let(:base_url) { nil }

            it "returns a HAL browser URL without base_url prefix" do
              expect(subject.url).to eq "/hal-browser/browser.html#/released_version"
            end
          end

          context "with base_url" do
            let(:base_url) { "/pact-broker-api" }

            it "returns a HAL browser URL with the base_url prefix" do
              expect(subject.url).to eq "/pact-broker-api/hal-browser/browser.html#/pact-broker-api/released_version"
            end
          end
        end
      end
    end
  end
end
