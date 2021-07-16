module PactBroker
  module Api
    module Resources
      module PaginationMethods
        def pagination_options
          {
            page_number: request.query["pageNumber"]&.to_i,
            page_size: request.query["pageSize"]&.to_i
          }.compact
        end
      end
    end
  end
end
