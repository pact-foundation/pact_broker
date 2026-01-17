# frozen_string_literal: true

require_relative 'find_content'

module OpenapiFirst
  class Router
    # @visibility private
    module FindResponse
      Match = Data.define(:response, :error)

      def self.call(responses, status, content_type, request_method:, path:)
        contents = find_status(responses, status)
        if contents.nil?
          message = "Status #{status} is not defined for #{request_method.upcase} #{path}. " \
                    "Defined statuses are: #{responses.keys.join(', ')}."
          return Match.new(error: Failure.new(:response_not_found, message:), response: nil)
        end
        response = FindContent.call(contents, content_type)
        return response_not_found(content_type:, contents:, request_method:, path:) unless response

        Match.new(response:, error: nil)
      end

      def self.response_not_found(content_type:, contents:, request_method:, path:)
        empty_content = content_type.nil? || content_type.empty?
        message =
          "Content-Type should be #{contents.keys.join(' or ')}, " \
          "but was #{empty_content ? 'empty' : content_type} for " \
          "#{request_method.upcase} #{path}"

        Match.new(
          error: Failure.new(:response_not_found, message:),
          response: nil
        )
      end
      private_class_method :response_not_found

      def self.find_status(responses, status)
        # According to OAS status has to be a string,
        # but there are a few API descriptions out there that use integers because of YAML.

        responses[status] || responses[status.to_s] ||
          responses["#{status / 100}XX"] ||
          responses["#{status / 100}xx"] ||
          responses['default']
      end
    end
  end
end
