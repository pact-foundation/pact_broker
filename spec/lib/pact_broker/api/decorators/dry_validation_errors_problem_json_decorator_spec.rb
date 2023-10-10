require "pact_broker/api/decorators/dry_validation_errors_problem_json_decorator"
require "pact_broker/api/decorators/validation_errors_problem_json_decorator"
require "pact_broker/api/contracts/base_contract"

module PactBroker
  module Api
    module Decorators
      describe DryValidationErrorsProblemJsonDecorator do
        describe "#to_json" do
          class TestContract < PactBroker::Api::Contracts::BaseContract
            json do
              optional(:foo).maybe(:hash) do
                required(:bar).filled(:string)
              end
            end
          end

          let(:decorator_options) { { user_options: { base_url: "http://example.org" } } }

          subject { DryValidationErrorsProblemJsonDecorator.new(validation_errors).to_hash(**decorator_options) }

          context "with a MessageSet of errors" do
            let(:validation_errors) do
              TestContract.new.call({ foo: { bar: 1 }}).errors
            end

            let(:expected_hash) do
              {
                "title" => "Validation errors",
                "type" => "http://example.org/problems/validation-error",
                "status" => 400,
                "instance" => "/",

                "errors" => [
                  {
                    "type" => "http://example.org/problems/invalid-body-property-value",
                    "pointer" => "/foo/bar",
                    "title" => "Invalid body parameter",
                    "detail" => "must be a string"
                  }
                ]
              }
            end

            it { is_expected.to match_pact(expected_hash, allow_unexpected_keys: false) }
          end

          context "it decorates the same way as the ValidationErrorsProblemJsonDecorator" do
            let(:validation_errors) do
              TestContract.new.call({ foo: { bar: 1 }}).errors
            end

            let(:decorated_hash) { ValidationErrorsProblemJsonDecorator.new(validation_errors.to_hash).to_hash(**decorator_options) }

            it "decorates the dry validation errors the same way as we decorate a hash of errors" do
              expect(subject).to eq decorated_hash
            end
          end

          context "when the top level details are customised via user_options" do
            let(:decorator_options) { { user_options: { title: "title", type: "type", detail: "detail", status: 409, instance: "/foo" } } }

            let(:expected_hash) do
              {
                "title" => "title",
                "type" => "type",
                "status" => 409,
                "instance" => "/foo",
                "detail" => "detail"
              }
            end

            let(:validation_errors) do
              TestContract.new.call({ foo: { bar: 1 }}).errors
            end

            it { is_expected.to match_pact(expected_hash, allow_unexpected_keys: true) }
          end
        end
      end
    end
  end
end
