module Pact
  module MockService
    class ResponseDecorator

      def initialize response
        @response = response
      end

      def to_json(options = {})
        as_json.to_json(options)
      end

      def as_json options = {}
        to_hash
      end

      def to_hash
        hash = {}
        hash[:status]  = response.status  if response.specified?(:status)
        hash[:headers] = response.headers if response.specified?(:headers)
        hash[:body]    = response.body    if response.specified?(:body)
        hash
      end

      private

      attr_reader :response

    end
  end
end
