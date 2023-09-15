require "pact_broker/api/decorators/configuration"

module PactBroker
  module Api
    module Decorators
      describe Configuration do
        describe "#validation_error_decorator_class_for" do
          let(:configuration) { Configuration.new }

          subject { configuration.validation_error_decorator_class_for(errors_class, accept_header) }

          context "when given Dry::Validation::MessageSet and application/hal+json, application/problem+json" do
            let(:errors_class) { Dry::Validation::MessageSet }
            let(:accept_header) { "application/hal+json, application/problem+json" }

            it { is_expected.to be PactBroker::Api::Decorators::DryValidationErrorsProblemJsonDecorator }
          end

          context "when given Hash and application/hal+json, application/problem+json" do
            let(:errors_class) { Hash }
            let(:accept_header) { "application/hal+json, application/problem+json" }

            it { is_expected.to be PactBroker::Api::Decorators::ValidationErrorsProblemJSONDecorator }
          end

          context "when given Dry::Validation::MessageSet and application/hal+json" do
            let(:errors_class) { Dry::Validation::MessageSet }
            let(:accept_header) { "application/hal+json" }

            it { is_expected.to be PactBroker::Api::Decorators::DryValidationErrorsDecorator }
          end

          context "when given Hash and application/hal+json" do
            let(:errors_class) { Hash }
            let(:accept_header) { "application/hal+json" }

            it { is_expected.to be PactBroker::Api::Decorators::ValidationErrorsDecorator }
          end
        end
      end
    end
  end
end
