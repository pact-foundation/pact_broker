require "pact_broker/api/decorators/dry_validation_errors_problem_json_decorator"
require "pact_broker/api/contracts/base_contract"

module PactBroker
  module Api
    module Decorators
      describe DryValidationErrorsProblemJSONDecorator do
        describe "#to_json" do

          class TestContract < PactBroker::Api::Contracts::BaseContract
            json do
              optional(:foo).maybe(:hash) do
                required(:bar).filled(:string)
              end
            end
          end

          let(:decorator_options) { { user_options: { base_url: "http://example.org" } } }

          subject { DryValidationErrorsProblemJSONDecorator.new(validation_errors).to_hash(**decorator_options) }

          context "with a hash of errors" do
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
                    "title" => "Validation error",
                    "detail" => "must be a string",
                    "status" => 400
                  }
                ]
              }
            end

            it { is_expected.to match_pact(expected_hash, allow_unexpected_keys: false)}
          end
        end
      end
    end
  end
end
