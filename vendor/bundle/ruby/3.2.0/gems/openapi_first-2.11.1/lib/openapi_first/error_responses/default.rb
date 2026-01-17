# frozen_string_literal: true

module OpenapiFirst
  module ErrorResponses
    # An error reponse that returns application/problem+json with a list of "errors"
    # See also https://www.rfc-editor.org/rfc/rfc9457.html
    class Default
      include OpenapiFirst::ErrorResponse

      OpenapiFirst.register_error_response(:default, self)

      TITLES = {
        not_found: 'Not Found',
        method_not_allowed: 'Request Method Not Allowed',
        unsupported_media_type: 'Unsupported Media Type',
        invalid_body: 'Bad Request Body',
        invalid_query: 'Bad Query Parameter',
        invalid_header: 'Bad Request Header',
        invalid_path: 'Bad Request Path',
        invalid_cookie: 'Bad Request Cookie'
      }.freeze
      private_constant :TITLES

      def body
        result = {
          title:,
          status:
        }
        result[:errors] = errors if failure.errors
        JSON.generate(result)
      end

      def type = failure.type

      def title
        TITLES.fetch(type)
      end

      def content_type
        'application/problem+json'
      end

      def errors
        key = pointer_key
        failure.errors.map do |error|
          {
            message: error.message,
            key => pointer(error.data_pointer),
            code: error.type
          }
        end
      end

      def pointer_key
        case type
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
        return data_pointer if type == :invalid_body

        data_pointer.delete_prefix('/')
      end
    end
  end
end
