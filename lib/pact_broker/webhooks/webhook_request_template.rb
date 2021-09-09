require "pact_broker/webhooks/render"
require "cgi"
require "pact_broker/domain/webhook_request"
require "pact_broker/string_refinements"

module PactBroker
  module Webhooks
    class WebhookRequestTemplate

      include PactBroker::Logging
      include PactBroker::Messages
      using PactBroker::StringRefinements

      HEADERS_TO_REDACT = [/authorization/i, /token/i]

      attr_accessor :method, :url, :body, :username, :password, :uuid
      attr_reader :headers

      # Reform gets confused by the :method method, as :method is a standard
      # Ruby method.
      alias_method :http_method, :method

      def initialize attributes = {}
        attributes.each do | (name, value) |
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
        @headers = Rack::Utils::HeaderHash.new(attributes[:headers] || {})
      end

      def build(template_params, user_agent)
        attributes = {
          method: http_method,
          url: build_url(template_params),
          headers: build_headers(template_params),
          username: build_string(username, template_params),
          password: build_string(password, template_params),
          uuid: uuid,
          body: build_body(template_params),
          user_agent: user_agent
        }
        PactBroker::Domain::WebhookRequest.new(attributes)
      end

      def description
        "#{http_method.upcase} #{URI(PactBroker::Webhooks::Render.render_with_placeholder(url)).host}"
      end

      def display_password
        password.nil? ? nil : (PactBroker::Webhooks::Render.includes_parameter?(password) ? password : "**********")
      end

      def redacted_headers
        headers.each_with_object({}) do | (name, value), new_headers |
          redact = HEADERS_TO_REDACT.any?{ | pattern | name =~ pattern }  && !PactBroker::Webhooks::Render.includes_parameter?(value)
          new_headers[name] = redact ? "**********" : value
        end
      end

      def headers= headers
        @headers = Rack::Utils::HeaderHash.new(headers)
      end

      def uses_parameter?(parameter_name)
        !!body_string&.include?("${" + parameter_name + "}")
      end

      def body_string
        String === body ? body : body&.to_json
      end

      def to_s
        "#{method.upcase} #{url}, username=#{username}, password=#{display_password}, headers=#{redacted_headers}, body=#{body}"
      end

      def template_parameters(scope = nil)
        body_template_parameters(scope) + url_template_parameters(scope) + header_template_parameters(scope) + credentials_template_parameters(scope)
      end

      def body_template_parameters(scope = nil)
        body_string.scan(parameter_pattern(scope)).flatten.uniq
      end

      def header_template_parameters(scope = nil)
        pattern = parameter_pattern(scope)
        headers.values.collect { |value| value.scan(pattern) }.flatten.uniq
      end

      def url_template_parameters(scope = nil)
        url.scan(parameter_pattern(scope)).flatten.uniq
      end

      def credentials_template_parameters(scope = nil)
        pattern = parameter_pattern(scope)
        [username, password].compact.collect do | credential |
          credential.scan(pattern)
        end.flatten.uniq
      end

      private

      def parameter_pattern(scope)
        scope ? /\${(#{scope}\.[a-zA-z]+)}/ : /\${([a-zA-z]+\.[a-zA-z]+)}/
      end

      def build_url(template_params)
        URI(PactBroker::Webhooks::Render.call(url, template_params){ | value | CGI::escape(value) if !value.nil? } ).to_s
      end

      def build_body(template_params)
        body_string = String === body ? body : body.to_json
        build_string(body_string, template_params)
      end

      def build_headers(template_params)
        headers.each_with_object(Rack::Utils::HeaderHash.new) do | (key, value), new_headers |
          new_headers[key] = build_string(value, template_params)
        end
      end

      def build_string(string, template_params)
        return string if string.nil? || string.blank?
        PactBroker::Webhooks::Render.call(string, template_params)
      end
    end
  end
end
