require "rack/utils"

module PactBroker
  module Matrix
    class ParseCanIDeployQuery
      # rubocop: disable Metrics/CyclomaticComplexity
      def self.call params
        selector = PactBroker::Matrix::UnresolvedSelector.new
        options = {
          latestby: "cvp"
        }

        if params[:pacticipant].is_a?(String)
          selector.pacticipant_name = params[:pacticipant]
        end

        if params[:version].is_a?(String)
          selector.pacticipant_version_number = params[:version]
        end

        if params[:to].is_a?(String)
          options[:tag] = params[:to]
          options[:latest] = true
        end

        if params[:environment].is_a?(String)
          options[:environment_name] = params[:environment]
          # Multiple versions of an integrated application can be simultaneously released to an
          # environment (record-release), or deployed to it on different targets (record-deployment).
          # "cvp" collapses these down to the latest provider version, hiding incompatible versions
          # that are still live. "cvpv" evaluates every co-resident version independently. See issue #903.
          options[:latestby] = "cvpv"
        end

        if params[:ignore].is_a?(Array)
          options[:ignore_selectors] = params[:ignore].collect do | param |
            if param.is_a?(String)
              PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: param)
            elsif param.is_a?(Hash) && param.key?(:pacticipant)
              PactBroker::Matrix::UnresolvedSelector.new({ pacticipant_name: param[:pacticipant], pacticipant_version_number: param[:version] }.compact)
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
