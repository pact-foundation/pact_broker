require "pact_broker/api/decorators/validation_errors_problem_json_decorator"

module PactBroker
  module Api
    module Decorators
      describe ValidationErrorsProblemJsonDecorator do
        describe "#to_json" do
          let(:decorator_options) { { user_options: { base_url: "http://example.org" } } }

          subject { ValidationErrorsProblemJsonDecorator.new(validation_errors).to_hash(**decorator_options) }

          context "with a hash of errors" do
            let(:validation_errors) do
              {
                contract: { content: ["this is some error text" ] }
              }
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
                    "pointer" => "/contract/content",
                    "title" => "Invalid body parameter",
                    "detail" => "this is some error text"
                  }
                ]
              }
            end

            it { is_expected.to match_pact(expected_hash, allow_unexpected_keys: false)}
          end

          context "with a hash of errors with dotted keys" do
            let(:validation_errors) do
              {
                :"contract.content" => ["this is some error text" ]
              }
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
                    "pointer" => "/contract/content",
                    "title" => "Invalid body parameter",
                    "detail" => "this is some error text"
                  }
                ]
              }
            end

            it { is_expected.to match_pact(expected_hash, allow_unexpected_keys: false)}
          end

          context "with an indexed hash of errors" do
            let(:validation_errors) do
              {
                contract: { content: { 1 => "this is some error text" } }
              }
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
                    "pointer" => "/contract/content/1",
                    "title" => "Invalid body parameter",
                    "detail" => "this is some error text"
                  }
                ]
              }
            end

            it { is_expected.to match_pact(expected_hash, allow_unexpected_keys: false)}
          end

          context "with an array of strings (PactBroker::Matrix::Service.validate_selectors returns this :grimace:)" do
            let(:validation_errors) do
              ["error 1", "error 2"]
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
                    "title" => "Invalid body parameter",
                    "detail" => "error 1"
                  },
                  {
                    "type" => "http://example.org/problems/invalid-body-property-value",
                    "title" => "Invalid body parameter",
                    "detail" => "error 2"
                  }
                ]
              }
            end

            it { is_expected.to match_pact(expected_hash, allow_unexpected_keys: false)}
          end

          context "with a string (shouldn't happen, but can't guarantee it doesn't" do
            let(:validation_errors) do
              "error 1"
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
                    "title" => "Invalid body parameter",
                    "detail" => "error 1"
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
