module PactBroker
  module Webhooks
    class URLRedactor
      # @url = attributes[:url]
      PARAMS_TO_REDACT = [/auth/i, /token/i]
      SLACK_URL = "hooks.slack.com/services/"
      attr_accessor :url
      def self.call url
        url = url
        if URI(url).query
          redact_secret_params(url)
        elsif url.include? SLACK_URL
          url.split("/")[0..5].join("/") + "/redacted"
        else
          url 
        end
      end

      def self.redact_secret_params url
        baseUrl = url.split("?")[0]
        paramHash = redact_params(url)
        redactedParams = encode_params(paramHash)
        baseUrl + "?" + redactedParams   
      end

      def self.redact_params url
        attr_accessor :url
        CGI.parse(URI.parse(url).query).each_with_object({}) do | (name, value), new_params |
          redact = PARAMS_TO_REDACT.any?{ | pattern | name =~ pattern }
          new_params[name] = redact ? "redacted" : value
        end
      end

      def self.encode_params(value, key = nil)
        case value
        when Hash  then value.map { |k,v| encode_params(v, append_key(key,k)) }.join('&')
        when Array then value.map { |v| encode_params(v, "#{key}") }.join('&')
        when nil then ''
        else
          "#{key}=#{CGI.escape(value)}" 
        end
      end

      def self.append_key(root_key, key)
        root_key.nil? ? key : "#{root_key}[#{key}]"
      end

    end
  end
end
