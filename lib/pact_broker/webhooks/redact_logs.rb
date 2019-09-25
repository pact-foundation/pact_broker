require 'pact_broker/string_refinements'

module PactBroker
  module Webhooks
    module RedactLogs
      HEADER_SUBSTITUTIONS = [[/(Authorization: )(.*)/i, '\1[REDACTED]'], [ /(Token: )(.*)/i, '\1[REDACTED]']]

      using PactBroker::StringRefinements

      def redact_logs(logs, values)
        RedactLogs.call(logs, values)
      end

      def self.call logs, values
        substitutions = HEADER_SUBSTITUTIONS + value_substitutions(values)

        substitutions.reduce(logs) do | logs, (find, replace) |
          logs.gsub(find, replace)
        end
      end

      def self.value_substitutions(values)
        values.select(&:not_blank?).collect{ | value | [value, "********"] }
      end
    end
  end
end
