require 'rack/utils'

module PactBroker
  module Matrix
    class ParseQuery
      def self.call query
        params = Rack::Utils.parse_nested_query(query)
        (params['q'] || []).collect{ |i| { pacticipant_name: i['pacticipant'], pacticipant_version_number: i['version'] } }
      end
    end
  end
end
