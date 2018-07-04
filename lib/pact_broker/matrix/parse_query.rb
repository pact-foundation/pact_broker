require 'rack/utils'

module PactBroker
  module Matrix
    class ParseQuery
      def self.call query
        params = Rack::Utils.parse_nested_query(query)
        selectors = (params['q'] || []).collect do |i|
          p = {}
          p[:pacticipant_name] = i['pacticipant'] if i['pacticipant'] && i['pacticipant'] != ''
          p[:pacticipant_version_number] = i['version'] if i['version'] && i['version'] != ''
          p[:latest] = true if i['latest'] == 'true'
          p[:tag] = i['tag'] if i['tag'] && i['tag'] != ''
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
        if params.key?('latestby') && params['latestby'] != ''
          options[:latestby] = params['latestby']
        end
        if params.key?('limit') && params['limit'] != ''
          options[:limit] = params['limit']
        end
        if params.key?('latest') && params['latest'] != ''
          options[:latest] = params['latest'] == 'true'
        end
        if params.key?('tag') && params['tag'] != ''
          options[:tag] = params['tag']
        end
        return selectors, options
      end
    end
  end
end
