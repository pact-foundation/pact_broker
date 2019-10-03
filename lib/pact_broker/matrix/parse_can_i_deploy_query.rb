require 'rack/utils'

module PactBroker
  module Matrix
    class ParseCanIDeployQuery
      def self.call params
        selector = {}
        options = {
          latestby: 'cvp',
          latest: true
        }

        if params[:pacticipant].is_a?(String)
          selector[:pacticipant_name] = params[:pacticipant]
        end

        if params[:version].is_a?(String)
          selector[:pacticipant_version_number] = params[:version]
        end

        if params[:to].is_a?(String)
          options[:tag] = params[:to]
        end

        return [selector], options
      end
    end
  end
end
