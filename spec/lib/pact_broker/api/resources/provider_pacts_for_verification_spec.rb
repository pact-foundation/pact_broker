require 'pact_broker/api/resources/provider_pacts_for_verification'

module PactBroker
  module Api
    module Resources
      describe ProviderPactsForVerification do
        before do
          allow(PactBroker::Pacts::Service).to receive(:find_for_verification).and_return(pacts)
          allow(PactBroker::Api::Decorators::VerifiablePactsDecorator).to receive(:new).and_return(decorator)
          allow_any_instance_of(ProviderPactsForVerification).to receive(:resource_exists?).and_return(provider)
        end

        let(:provider) { double('provider') }
        let(:pacts) { double('pacts') }
        let(:path) { '/pacts/provider/Bar/for-verification' }
        let(:decorator) { instance_double('PactBroker::Api::Decorators::VerifiablePactsDecorator') }

        subject { get(path, provider_version_tags: ['master'], consumer_version_selectors: [ { tag: "dev", latest: true}]) }

        it "finds the pacts for verification by the provider" do
          # Naughty not mocking out the query parsing...
          expect(PactBroker::Pacts::Service).to receive(:find_for_verification).with("Bar", ["master"], [ OpenStruct.new(tag: "dev", latest: true)])
          subject
        end

        it "sets the correct resource title" do
          expect(decorator).to receive(:to_json) do | options |
            expect(options[:user_options][:title]).to eq "Pacts to be verified by provider Bar"
          end
          subject
        end
      end
    end
  end
end
