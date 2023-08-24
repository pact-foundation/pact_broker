require "rack/utils"
require "pact_broker/matrix/unresolved_selector"

module PactBroker
  module Matrix
    class ParseQuery
      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/MethodLength
      def self.call query
        params = Rack::Utils.parse_nested_query(query)
        selectors = (params["q"] || []).collect do |i|
          parse_selector(i)
        end
        options = {}
        if params.key?("success") && params["success"].is_a?(Array)
          options[:success] = params["success"].collect do | value |
            value == "" ? nil : value == "true"
          end
        end

        if params.key?("success") && params["success"].is_a?(String)
          options[:success] = [params["success"] == "" ? nil : params["success"] == "true"]
        end

        if params.key?("latestby") && params["latestby"] != ""
          options[:latestby] = params["latestby"]
        end

        # Don't think this is used anywhere...
        if params.key?("days") && params["days"] != ""
          options[:days] = params["days"].to_i
        end

        if params.key?("limit") && params["limit"] != ""
          options[:limit] = params["limit"]
        else
          options[:limit] = "100"
        end

        if params.key?("latest") && params["latest"] != ""
          options[:latest] = params["latest"] == "true"
        end

        if params.key?("tag") && params["tag"] != ""
          options[:tag] = params["tag"]
        end

        if params.key?("environment") && params["environment"] != ""
          options[:environment_name] = params["environment"]
        end

        if params.key?("mainBranch") && params["mainBranch"] != ""
          options[:main_branch] = params["mainBranch"] == "true"
        end

        if params["ignore"].is_a?(Array)
          options[:ignore_selectors] = params["ignore"].collect{ |i| parse_selector(i) }
        else
          options[:ignore_selectors] = []
        end

        return selectors, options
      end

      def self.parse_selector(i)
        p = PactBroker::Matrix::UnresolvedSelector.new
        p.pacticipant_name = i["pacticipant"] if i["pacticipant"] && i["pacticipant"] != ""
        p.pacticipant_version_number = i["version"] if i["version"] && i["version"] != ""
        p.latest = true if i["latest"] == "true"
        p.branch = i["branch"] if i["branch"] && i["branch"] != ""
        p.tag = i["tag"] if i["tag"] && i["tag"] != ""
        p.environment_name = i["environment"] if i["environment"] && i["environment"] != ""
        p.main_branch = true if i["mainBranch"] && i["mainBranch"] == "true"
        p
      end
      # rubocop: enable Metrics/CyclomaticComplexity
    end
  end
end
