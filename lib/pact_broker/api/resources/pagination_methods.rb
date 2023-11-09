module PactBroker
  module Api
    module Resources
      module PaginationMethods
        def pagination_options
          if request.query["page"] || request.query["size"]
            {
              page_number: request.query["page"]&.to_i || 1,
              page_size: request.query["size"]&.to_i || 100
            }
          elsif request.query["pageNumber"] || request.query["pageSize"]
            {
              page_number: request.query["pageNumber"]&.to_i || 1,
              page_size: request.query["pageSize"]&.to_i || 100
            }
          else
            {}
          end
        end

        def default_pagination_options
          { page_number: 1, page_size: 100 }
        end
      end
    end
  end
end
