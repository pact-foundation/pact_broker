require 'pact_broker/api/decorators/verifiable_pacts_decorator'

module PactBroker
  module Api
    module Decorators
      describe VerifiablePactsDecorator do
        before do
          allow(VerifiablePactDecorator).to receive(:new).and_return(verifiable_pact_decorator)
        end
        let(:verifiable_pact_decorator) { instance_double(VerifiablePactDecorator).as_null_object }
        let(:pact) { double('pact') }
        let(:decorator) { VerifiablePactsDecorator.new([pact]) }
        let(:options) { { user_options: { resource_url: 'http://example.org/pacts' } } }

        let(:json) { decorator.to_json(options) }

        subject { JSON.parse(json) }

        it "includes a list of verifiable pacts" do
          expect(subject["_embedded"]["pacts"]).to be_an(Array)
        end

        it "includes a link to itself" do
          expect(subject["_links"]["self"]["href"]).to eq "http://example.org/pacts"
        end
      end
    end
  end
end
