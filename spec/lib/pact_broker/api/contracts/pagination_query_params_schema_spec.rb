require "pact_broker/api/contracts/pagination_query_params_schema"

module PactBroker
  module Api
    module Contracts
      describe PaginationQueryParamsSchema do
        include PactBroker::Test::ApiContractSupport

        let(:params) do
          {}
        end

        subject { format_errors_the_old_way(PaginationQueryParamsSchema.call(params)) }

        context "with empty params" do
          it { is_expected.to be_empty }
        end

        context "with values that are not numeric" do
          let(:params) do
            {
              "pageNumber" => "a",
              "pageSize" => "3.2"
            }
          end

          its([:pageNumber]) { is_expected.to contain_exactly(match("integer"))}
          its([:pageSize]) { is_expected.to contain_exactly(match("integer"))}
        end

        context "with values that are 0" do
          let(:params) do
            {
              "pageNumber" => "-0",
              "pageSize" => "-0"
            }
          end

          its([:pageNumber]) { is_expected.to contain_exactly(match(/greater.*1/))}
          its([:pageSize]) { is_expected.to contain_exactly(match(/greater.*1/))}
        end
      end
    end
  end
end
