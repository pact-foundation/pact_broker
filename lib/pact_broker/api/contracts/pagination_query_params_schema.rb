
module PactBroker
  module Api
    module Contracts
      class PaginationQueryParamsSchema < BaseContract
        params do
          # legacy format
          optional(:pageNumber).maybe(:integer).value(gteq?: 1)
          optional(:pageSize).maybe(:integer).value(gteq?: 1)

          # desired format
          optional(:page).maybe(:integer).value(gteq?: 1)
          optional(:size).maybe(:integer).value(gteq?: 1)
        end
      end
    end
  end
end
