module PactBroker
  module Api
    module Resources
      module FilterMethods
        def filter_options
          if request.query.has_key?("q")
            { query_string: request.query["q"] }
          else
            {}
          end
        end
      end
    end
  end
end
