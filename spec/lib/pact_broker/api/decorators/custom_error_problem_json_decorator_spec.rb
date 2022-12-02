require "pact_broker/api/decorators/custom_error_problem_json_decorator"

module PactBroker
  module Api
    module Decorators
      describe CustomErrorProblemJSONDecorator do
        let(:decorator_options) { { user_options: { base_url: "http://example.org" } } }
        let(:params) { { title: "Title", type: "type", detail: "Detail", status: 400 } }

        subject { CustomErrorProblemJSONDecorator.new(**params).to_hash(decorator_options) }

        let(:expected_hash) do
          {
            "detail" => "Detail", "status" => 400, "title" => "Title", "type" => "http://example.org/problem/type"
          }
        end

        it { is_expected.to eq expected_hash }
      end
    end
  end
end
