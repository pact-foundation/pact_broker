require "pact_broker/api/decorators/validation_errors_problem_json_decorator"

module PactBroker
  module Api
    module Decorators
      describe ValidationErrorsProblemJSONDecorator do
        let(:validation_errors) do
          {
            contract: { content: ["this is some error text" ] }
          }
        end

        let(:decorator_options) { { user_options: { base_url: "http://example.org" } } }
        subject { ValidationErrorsProblemJSONDecorator.new(validation_errors).to_hash(decorator_options) }

        describe "#to_json" do
          let(:expected_hash) do
            {
              "title" => "Validation errors",
              "type" => "http://example.org/problems/validation-error",
              "status" => 400,

              "errors" => [
                {
                  "type" => "http://example.org/problems/invalid-body-property-value",
                  "instance" => "/contract/content",
                  "title" => "Validation error",
                  "detail" => "this is some error text",
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
