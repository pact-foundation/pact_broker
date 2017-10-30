require 'rack/utils'

module PactBroker
  module Matrix
    class ParseQuery
      def self.call query
        params = Rack::Utils.parse_nested_query(query)
        selectors = (params['q'] || []).collect{ |i| { pacticipant_name: i['pacticipant'], pacticipant_version_number: i['version'] } }
        options = {}
        if params.key?('success') && params['success'].is_a?(Array)
          options[:success] = params['success'].collect do | value |
            value == '' ? nil : value == 'true'
          end
        end
        if params.key?('success') && params['success'].is_a?(String)
          options[:success] = [params['success'] == '' ? nil : params['success'] == 'true']
        end
        return selectors, options
      end
    end
  end
end
