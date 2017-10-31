require 'rack/utils'

module PactBroker
  module Matrix
    class ParseQuery
      def self.call query
        params = Rack::Utils.parse_nested_query(query)
        selectors = (params['q'] || []).collect do |i|
          p = {}
          p[:pacticipant_name] = i['pacticipant'] if i['pacticipant']
          p[:pacticipant_version_number] = i['version'] if i['version']
          p[:latest] = true if i['latest'] == 'true'
          p[:tag] = i['tag'] if i['tag']
          p
        end
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
