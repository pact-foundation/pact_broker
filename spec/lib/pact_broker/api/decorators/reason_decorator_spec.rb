require 'pact_broker/api/decorators/reason_decorator'
require 'pact_broker/matrix/reason'

module PactBroker
  module Api
    module Decorators
      describe ReasonDecorator do
        REASON_CLASSES = ObjectSpace.each_object(Class).select { |klass| klass < PactBroker::Matrix::Reason && klass.name&.start_with?("PactBroker") }

        describe "the number of Reason classes" do
          let(:expected_number_of_reason_classes) { 13 }

          it "is 13 - this is a reminder to add another spec here if a new Reason is added" do
            expect(REASON_CLASSES.size).to eq expected_number_of_reason_classes
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

            its(:to_s) { is_expected.to eq "The verification for the pact between version 2 of Foo and version 6 of Bar failed" }
          end

          context "when the reason is PactBroker::Matrix::NoDependenciesMissing" do
            let(:reason) { PactBroker::Matrix::NoDependenciesMissing.new }

            its(:to_s) { is_expected.to eq "There are no missing dependencies" }
          end

          context "when the reason is PactBroker::Matrix::Successful" do
            let(:reason) { PactBroker::Matrix::Successful.new }

            its(:to_s) { is_expected.to eq "All required verification results are published and successful" }
          end

          context "when the reason is PactBroker::Matrix::IgnoreSelectorDoesNotExist" do
            let(:reason) { PactBroker::Matrix::IgnoreSelectorDoesNotExist.new(selector) }
            let(:selector) {  double('consumer selector', description: "version 2 of Foo (no such version exists)") }

            its(:to_s) { is_expected.to eq "WARNING: Cannot ignore version 2 of Foo (no such version exists)" }
          end

          context "when the reason is PactBroker::Matrix::InteractionsMissingVerifications" do
            let(:reason) { PactBroker::Matrix::InteractionsMissingVerifications.new(consumer_selector, provider_selector, interactions) }
            let(:interactions) do
              [
                {
                  "description" => "desc1",
                  "providerState" => "p2"
                },{
                  "description" => "desc1",
                  "providerStates" => [ { "name" => "desc3"}, { "name" => "desc4"} ]
                }
              ]
            end

            its(:to_s) { is_expected.to eq "WARNING: Although the verification was reported as successful, the results for version 2 of Foo and version 6 of Bar may be missing tests for the following interactions: desc1 given p2; desc1 given desc3, desc4" }
          end
        end
      end
    end
  end
end
