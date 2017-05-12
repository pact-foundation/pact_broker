module PactBroker
  module Verifications
    class SummaryForConsumerVersion

      attr_reader :verifications

      def initialize verifications, pacts
        @verifications = verifications
        @pacts = pacts
      end

      def success
        successful.count == pacts.count
      end

      def provider_summary
        OpenStruct.new(
          successful: successful,
          failed: failed,
          unknown: unknown
          )
      end

      private

      attr_reader :pacts

      def successful
        verifications.select(&:success).collect(&:provider_name)
      end

      def failed
        verifications.select{|verification| !verification.success }.collect(&:provider_name)
      end

      def unknown
        pacts.collect(&:provider_name) - verifications.collect(&:provider_name)
      end
    end
  end
end
