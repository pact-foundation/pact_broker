# frozen_string_literal: true

module OpenapiFirst
  module ErrorResponses
    # A JSON:API conform error response. See https://jsonapi.org/.
    class Jsonapi
      include OpenapiFirst::ErrorResponse

      OpenapiFirst.register_error_response(:jsonapi, self)

      def body
        JSON.generate({ errors: serialized_errors })
      end

      def content_type
        'application/vnd.api+json'
      end

      def serialized_errors
        return default_errors unless failure.errors

        key = pointer_key
        failure.errors.map do |error|
          {
            status: status.to_s,
            source: { key => pointer(error.data_pointer) },
            title: error.message,
            code: error.type
          }
        end
      end

      def default_errors
        [{
          status: status.to_s,
          title: Rack::Utils::HTTP_STATUS_CODES[status]
        }]
      end

      def pointer_key
        case failure.type
        when :invalid_body
          :pointer
        when :invalid_query, :invalid_path
          :parameter
        when :invalid_header
          :header
        when :invalid_cookie
          :cookie
        end
      end

      def pointer(data_pointer)
        return data_pointer if failure.type == :invalid_body

        data_pointer.delete_prefix('/')
      end
    end
  end
end
