module PactBroker
  module Contracts
    Notice = Struct.new(:type, :text) do
      def self.info(text)
        Notice.new("info", text)
      end

      def self.debug(text)
        Notice.new("debug", text)
      end

      def self.warning(text)
        Notice.new("warning", text)
      end

      def self.prompt(text)
        Notice.new("prompt", text)
      end

      def self.success(text)
        Notice.new("success", text)
      end

      def self.error(text)
        Notice.new("error", text)
      end

      def error?
        type == "error"
      end
    end
  end
end
