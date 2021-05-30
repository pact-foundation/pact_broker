module PactBroker
  module Webhooks
    class Status

      def initialize _pact, webhooks, latest_triggered_webhooks
        @webhooks = webhooks
        @latest_triggered_webhooks = latest_triggered_webhooks
      end

      def to_s
        to_sym.to_s
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      def to_sym
        return :none if webhooks.empty?
        return :not_run if latest_triggered_webhooks.empty? || latest_triggered_webhooks.all?{|w| w.status == "not_run"}
        if latest_triggered_webhooks.any?{|w| w.status == "retrying" }
          return :retrying
        end
        latest_triggered_webhooks.all?{|w| w.status == "success"} ? :success : :failure
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      private

      attr_reader :webhooks, :latest_triggered_webhooks

    end
  end
end
