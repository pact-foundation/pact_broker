module PactBroker
  module Contracts
    LogMessage = Struct.new(:level, :message) do
      def self.info(message)
        LogMessage.new("info", message)
      end

      def self.warn(message)
        LogMessage.new("warn", message)
      end

      def self.debug(message)
        LogMessage.new("debug", message)
      end
    end
  end
end
