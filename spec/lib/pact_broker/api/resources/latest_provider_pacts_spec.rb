require 'pact_broker/api/resources/latest_provider_pacts'

module PactBroker
  module Api
    module Resources
      describe LatestProviderPacts do
        before do
          allow(PactBroker::Pacts::Service).to receive(:find_latest_pact_versions_for_provider).and_return(pacts)
          allow(PactBroker::Api::Decorators::ProviderPactsDecorator).to receive(:new).and_return(decorator)
          allow_any_instance_of(LatestProviderPacts).to receive(:resource_exists?).and_return(provider)
        end

        let(:provider) { double('provider') }
        let(:pacts) { double('pacts') }
        let(:path) { '/pacts/provider/Bar/latest' }
        let(:decorator) { instance_double('PactBroker::Api::Decorators::ProviderPactsDecorator') }

        subject { get path; last_response }

        context "with no tag" do
          it "finds the pacts" do
            expect(PactBroker::Pacts::Service).to receive(:find_latest_pact_versions_for_provider).with("Bar", tag: nil)
            subject
          end

          it "sets the correct resource title" do
            expect(decorator).to receive(:to_json) do | options |
              expect(options[:user_options][:title]).to eq "Latest pact versions for the provider Bar"
            end
            subject
          end
        end

        context "with a tag" do
          let(:path) { '/pacts/provider/Bar/latest/prod' }

          it "finds the pacts with a tag" do
            expect(PactBroker::Pacts::Service).to receive(:find_latest_pact_versions_for_provider).with("Bar", tag: "prod")
            subject
          end

          it "sets the correct resource title" do
            expect(decorator).to receive(:to_json) do | options |
              expect(options[:user_options][:title]).to eq "Latest pact versions for the provider Bar with consumer version tag 'prod'"
            end
            subject
          end
        end
      end
    end
  end
end
