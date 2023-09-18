# This is a VERY basic coverage checker.
# It only checks at the path/http method/response status level.
# TODO: add checks for different content types

module OpenapiFirst
  class PactBrokerCoverage
    attr_reader :to_be_called

    def initialize(app, to_be_called)
      @app = app
      @to_be_called = to_be_called
    end

    def call(env)
      response = @app.call(env)
      operation = env[OpenapiFirst::OPERATION]
      @to_be_called.delete(self.class.endpoint_id(operation, response[0])) if operation
      response
    end

    # helper method
    # @param [OpenapiFirst::Definition] spec
    def self.build_endpoints_list(spec)
      spec.operations.flat_map do |operation|
        operation["responses"].flat_map do | (status, _response) |
          endpoint_id(operation, status)
        end
      end
    end

    private

    def self.endpoint_id(operation, status)
      "#{operation.path}##{operation.method} #{status}"
    end
  end
end
