require 'pact_broker/api/decorators/verifiable_pacts_query_decorator'

module PactBroker
  module Api
    module Decorators
      describe VerifiablePactsQueryDecorator do
        let(:params) do
          {
            "provider_version_tags" => provider_version_tags,
            "consumer_version_selectors" => consumer_version_selectors
          }
        end
        let(:provider_version_tags) { %w[dev] }
        let(:consumer_version_selectors) do
          [{"tag" => "dev", "ignored" => "foo"}]
        end

        subject { VerifiablePactsQueryDecorator.new(OpenStruct.new).from_hash(params)  }

        context "when latest is not specified" do
          it "defaults to nil" do
            expect(subject.consumer_version_selectors.first.latest).to be nil
          end
        end

        context "when there are no consumer_version_selectors" do
          let(:params) { {} }

          it "returns an empty array" do
            expect(subject.consumer_version_selectors).to eq []
          end
        end
      end
    end
  end
end
