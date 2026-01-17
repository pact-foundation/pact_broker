module Pact
  module MockService
    class RequestDecorator

      def initialize request
        @request = request
      end

      def to_json(options = {})
        as_json.to_json(options)
      end

      def as_json options = {}
        to_hash
      end

      def to_hash
        hash = {
          method: request.method,
          path: request.path,
        }

        hash[:query]   = request.query   if request.specified?(:query)
        hash[:headers] = request.headers if request.specified?(:headers)
        hash[:body]    = request.body    if request.specified?(:body)
        hash[:options] = request.options if request.options.any?
        hash
      end

      private

      attr_reader :request

    end
  end
end
