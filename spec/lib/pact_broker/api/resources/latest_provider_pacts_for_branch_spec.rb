require "pact_broker/api/resources/latest_provider_pacts_for_branch"

module PactBroker
  module Api
    module Resources
      describe LatestProviderPactsForBranch do
        before do
          allow(PactBroker::Pacts::Service).to receive(:find_latest_pacts_for_provider_by_consumer_branch).and_return(pacts)
          allow(PactBroker::Api::Decorators::ProviderPactsDecorator).to receive(:new).and_return(decorator)
          allow_any_instance_of(LatestProviderPactsForBranch).to receive(:resource_exists?).and_return(provider)
        end

        let(:provider) { double("provider") }
        let(:pacts) { double("pacts") }
        let(:path) { "/pacts/provider/Bar/branch/prod/latest" }
        let(:decorator) { instance_double("PactBroker::Api::Decorators::ProviderPactsDecorator") }

        subject { get path; last_response }

        context "with a branch" do
          it "finds the pacts with a branch" do
            expect(PactBroker::Pacts::Service).to receive(:find_latest_pacts_for_provider_by_consumer_branch).with("Bar", branch_name: "prod", main_branch: false)
            subject
          end

          it "sets the correct resource title" do
            expect(decorator).to receive(:to_json) do | options |
              expect(options[:user_options][:title]).to eq "Latest pact versions for the provider Bar with consumer version branch 'prod'"
            end
            subject
          end
        end
      end
    end
  end
end
