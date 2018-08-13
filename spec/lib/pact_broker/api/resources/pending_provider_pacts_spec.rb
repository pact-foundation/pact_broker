require 'pact_broker/api/resources/latest_provider_pacts'

module PactBroker
  module Api
    module Resources
      describe PendingProviderPacts do
        before do
          allow(PactBroker::Pacts::Service).to receive(:find_pending_pact_versions_for_provider).and_return(pacts)
          allow(PactBroker::Api::Decorators::ProviderPactsDecorator).to receive(:new).and_return(decorator)
          allow_any_instance_of(PendingProviderPacts).to receive(:resource_exists?).and_return(provider)
        end

        let(:provider) { double('provider') }
        let(:pacts) { double('pacts') }
        let(:path) { '/pacts/provider/Bar/pending' }
        let(:decorator) { instance_double('PactBroker::Api::Decorators::ProviderPactsDecorator') }

        subject { get path; last_response }

        it "finds the pending pacts for the provider" do
          expect(PactBroker::Pacts::Service).to receive(:find_pending_pact_versions_for_provider).with("Bar")
          subject
        end

        it "sets the correct resource title" do
          expect(decorator).to receive(:to_json) do | options |
            expect(options[:user_options][:title]).to eq "Pending pact versions for the provider Bar"
          end
          subject
        end
      end
    end
  end
end
