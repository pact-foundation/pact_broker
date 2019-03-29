require 'pact_broker/api/decorators/reason_decorator'
require 'pact_broker/matrix/reason'

module PactBroker
  module Api
    module Decorators
      describe ReasonDecorator do

        REASON_CLASSES = ObjectSpace.each_object(Class).select { |klass| klass < PactBroker::Matrix::Reason }

        describe "the number of Reason classes" do
          it "is 9 - add another spec here if a new Reason is added" do
            expect(REASON_CLASSES.size).to eq 9
          end
        end

        describe "#to_s" do

          let(:consumer_selector) { double('consumer selector', description: "version 2 of Foo") }
          let(:provider_selector) { double('provider selector', description: "version 6 of Bar") }
          let(:selectors) { [consumer_selector, provider_selector] }

          subject { ReasonDecorator.new(reason) }

          context "when the reason is PactBroker::Matrix::PactNotEverVerifiedByProvider" do
            let(:reason) { PactBroker::Matrix::PactNotEverVerifiedByProvider.new(*selectors) }
            let(:provider_selector) { double('provider selector', description: "any version of Bar") }

            its(:to_s) { is_expected.to eq "There is no verified pact between version 2 of Foo and any version of Bar" }
          end

          context "when the reason is PactBroker::Matrix::PactNotVerifiedByRequiredProviderVersion" do
            let(:reason) { PactBroker::Matrix::PactNotVerifiedByRequiredProviderVersion.new(*selectors) }

            its(:to_s) { is_expected.to eq "There is no verified pact between version 2 of Foo and version 6 of Bar" }
          end

          context "when the reason is PactBroker::Matrix::VerificationFailed" do
            let(:reason) { PactBroker::Matrix::VerificationFailed.new(*selectors) }

            its(:to_s) { is_expected.to eq "The verification between version 2 of Foo and version 6 of Bar failed" }
          end

          context "when the reason is PactBroker::Matrix::NoDependenciesMissing" do
            let(:reason) { PactBroker::Matrix::NoDependenciesMissing.new }

            its(:to_s) { is_expected.to eq "There are no missing dependencies" }
          end

          context "when the reason is PactBroker::Matrix::Successful" do
            let(:reason) { PactBroker::Matrix::Successful.new }

            its(:to_s) { is_expected.to eq "All required verification results are published and successful" }
          end
        end
      end
    end
  end
end
