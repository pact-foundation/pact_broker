# frozen_string_literal: true

module OpenapiFirst
  # This is the base module for error responses
  module ErrorResponse
    ## @param failure [OpenapiFirst::Failure]
    def initialize(failure: nil)
      @failure = failure
    end

    attr_reader :failure

    # The response body
    def body
      raise "#{self.class} must implement the method #{__method__}"
    end

    # The response content-type
    def content_type
      raise "#{self.class} must implement the method #{__method__}"
    end

    STATUS = {
      not_found: 404,
      method_not_allowed: 405,
      unsupported_media_type: 415
    }.freeze
    private_constant :STATUS

    # The response status
    def status
      STATUS[failure.type] || 400
    end

    # Render this error response
    def render
      Rack::Response.new(body, status, Rack::CONTENT_TYPE => content_type).finish
    end
  end
end
