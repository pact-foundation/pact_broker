require "rack/utils"
require "pact_broker/matrix/unresolved_selector"

module PactBroker
  module Matrix
    class ParseCanIDeployQuery
      # rubocop: disable Metrics/CyclomaticComplexity
      def self.call params
        selector = PactBroker::Matrix::UnresolvedSelector.new
        options = {
          latestby: "cvp",
          latest: true
        }

        if params[:pacticipant].is_a?(String)
          selector.pacticipant_name = params[:pacticipant]
        end

        if params[:version].is_a?(String)
          selector.pacticipant_version_number = params[:version]
        end

        if params[:to].is_a?(String)
          options[:tag] = params[:to]
        end

        if params[:environment].is_a?(String)
          options[:environment_name] = params[:environment]
        end

        if params[:ignore].is_a?(Array)
          options[:ignore_selectors] = params[:ignore].collect do | pacticipant_name |
            if pacticipant_name.is_a?(String)
              PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: pacticipant_name)
            end
          end.compact
        else
          options[:ignore_selectors] = []
        end

        return [selector], options
      end
      # rubocop: enable Metrics/CyclomaticComplexity
    end
  end
end
