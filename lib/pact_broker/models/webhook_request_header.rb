module PactBroker
  module Models
    class WebhookRequestHeader

      attr_accessor :name, :value

      def initialize name, value
        @name = name
        @value = value
      end
    end
  end
end
