module PactBroker
  module Webhooks
    class RedactLogs
      def self.call logs
        logs.gsub(/(Authorization: )(.*)/i,'\1[REDACTED]')
            .gsub(/(Token: )(.*)/i,'\1[REDACTED]')
      end
    end
  end
end
