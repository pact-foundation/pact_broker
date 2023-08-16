require "webmachine/errors"
require "pact_broker/string_refinements"

# Monkey patches the render_error method so that it returns hal+json or problem+json instead of text/html

module Webmachine
  using PactBroker::StringRefinements

  class << self
    alias_method :original_render_error, :render_error
  end

  # Renders a standard error message body for the response. The
  # standard messages are defined in localization files.
  # @param [Integer] code the response status code
  # @param [Request] req the request object
  # @param [Response] req the response object
  # @param [Hash] options keys to override the defaults when rendering
  #     the response body
  def self.render_error(code, req, res, options={})
    if text_html_error_content_type?(req)
      Webmachine.original_render_error(code, req, res, options)
    else
      render_error_for_api(code, req, res, options)
    end
  end

  def self.render_error_for_api(code, req, res, options)
    res.code = code
    unless res.body
      title, message = t(["errors.#{code}.title", "errors.#{code}.message"],
                         **{ :method => req.method,
                           :error => res.error}.merge(options))

      title = options[:title] if options[:title]
      message = options[:message] if options[:message]

      res.body = error_response_body(req, message, title, title.dasherize.gsub(/^\d+\-/, ""), code, req)
      res.headers[CONTENT_TYPE] = error_response_content_type(req)
    end
    ensure_content_length(res)
    ensure_date_header(res)
  end

  def self.text_html_error_content_type?(request)
    request.headers["Accept"]&.include?("text/html")
  end

  def self.problem_json_error_content_type?(request)
    request.headers["Accept"]&.include?("application/problem+json")
  end

  def self.error_response_content_type(request)
    if problem_json_error_content_type?(request)
      "application/problem+json;charset=utf-8"
    elsif text_html_error_content_type?(request)
      "text/html;charset=utf-8"
    else
      "application/json;charset=utf-8"
    end
  end

  # rubocop: disable Metrics/ParameterLists
  def self.error_response_body(req, detail, title, type, status, request)
    if problem_json_error_content_type?(request)
      req.path_info[:application_context].decorator_configuration.class_for(:custom_error_problem_json_decorator).new(detail: detail, title: title, type: type, status: status).to_json
    else
      req.path_info[:application_context].decorator_configuration.class_for(:error_decorator).new(detail).to_json
    end
  end
  # rubocop: enable Metrics/ParameterLists
end
