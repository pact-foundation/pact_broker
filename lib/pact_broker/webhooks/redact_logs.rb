require "pact_broker/string_refinements"

module PactBroker
  module Webhooks
    module RedactLogs
      HEADER_SUBSTITUTIONS = [[/(Authorization: )(.*)/i, '\1[REDACTED]'], [ /(Token: )(.*)/i, '\1[REDACTED]']]

      using PactBroker::StringRefinements

      def redact_logs(logs, values, pattern_substitutions = [])
        RedactLogs.call(logs, values, pattern_substitutions)
      end

      def self.call logs, values, pattern_substitutions = []
        substitutions = HEADER_SUBSTITUTIONS + pattern_substitutions + value_substitutions(values)

        substitutions.reduce(logs) do | agg_logs, (find, replace) |
          agg_logs.gsub(find, replace)
        end
      end

      def self.value_substitutions(values)
        values.select(&:not_blank?).collect{ | value | [value, "********"] }
      end
    end
  end
end
