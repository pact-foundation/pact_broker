require 'rack/utils'

module PactBroker
  module Matrix
    class ParseQuery
      def self.call query
        params = Rack::Utils.parse_nested_query(query)
        (params['q'] || []).each_with_object({}) do | selector, hash |
          hash[selector['pacticipant']] = selector['version']
        end
      end
    end
  end
end
