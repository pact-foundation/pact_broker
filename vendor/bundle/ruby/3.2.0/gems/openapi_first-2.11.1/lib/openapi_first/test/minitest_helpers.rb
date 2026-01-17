# frozen_string_literal: true

module OpenapiFirst
  module Test
    # Assertion methods for Minitest
    module MinitestHelpers
      # :nocov:
      def assert_api_conform(status: nil, api: openapi_first_default_api)
        api = OpenapiFirst::Test[api]
        request = respond_to?(:last_request) ? last_request : @request
        response = respond_to?(:last_response) ? last_response : @response

        if status
          assert_equal status, response.status,
                       "Expected status #{status}, but got #{response.status} " \
                       "from #{request.request_method.upcase} #{request.path}."
        end

        validated_request = api.validate_request(request, raise_error: false)
        validated_response = api.validate_response(request, response, raise_error: false)

        assert validated_request.valid?, validated_request.error&.exception_message
        assert validated_response.valid?, validated_response.error&.exception_message
      end
      # :nocov:
    end
  end
end
