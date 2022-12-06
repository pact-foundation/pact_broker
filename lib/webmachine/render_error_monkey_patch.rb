require "webmachine/errors"
require "pact_broker/string_refinements"

# Monkey patches the render_error method so that it returns hal+json or problem+json instead of text/html

module Webmachine
  using PactBroker::StringRefinements

  # Renders a standard error message body for the response. The
  # standard messages are defined in localization files.
  # @param [Integer] code the response status code
  # @param [Request] req the request object
  # @param [Response] req the response object
  # @param [Hash] options keys to override the defaults when rendering
  #     the response body
  def self.render_error(code, req, res, options={})
    res.code = code
    unless res.body
      title, message = t(["errors.#{code}.title", "errors.#{code}.message"],
                         { :method => req.method,
                           :error => res.error}.merge(options))

      title = options[:title] if options[:title]
      message = options[:message] if options[:message]

      res.body = error_response_body(message, title, title.dasherize.gsub(/^\d+\-/, ""), code, req)
      res.headers[CONTENT_TYPE] = error_response_content_type(req)
    end
    ensure_content_length(res)
    ensure_date_header(res)
  end

  def self.problem_json_error_content_type?(request)
    request.headers["Accept"]&.include?("application/problem+json")
  end

  def self.error_response_content_type(request)
    if problem_json_error_content_type?(request)
      "application/problem+json;charset=utf-8"
    else
      "application/json;charset=utf-8"
    end
  end

  def self.error_response_body(detail, title, type, status, request)
    if problem_json_error_content_type?(request)
      PactBroker::Api::Decorators::CustomErrorProblemJSONDecorator.new(detail: detail, title: title, type: type, status: status).to_json
    else
      { error: detail }.to_json
    end
  end
end
