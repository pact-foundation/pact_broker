module PactBroker
  module Api
    module Resources
      module PaginationMethods
        def pagination_options
          {
            page_number: request.query["pageNumber"]&.to_i || 1,
            page_size: request.query["pageSize"]&.to_i || 100
          }
        end
      end
    end
  end
end
