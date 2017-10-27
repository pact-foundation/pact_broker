require 'cgi'

module PactBroker
  module Matrix
    class ParseQuery
      def self.call query
        params = CGI.parse(CGI.unescape(query))
        params['pacticipant[]'].zip(params['version[]']).each_with_object({}) do | (pacticipant, version), hash |
          hash[pacticipant] = version
        end
      end
    end
  end
end
