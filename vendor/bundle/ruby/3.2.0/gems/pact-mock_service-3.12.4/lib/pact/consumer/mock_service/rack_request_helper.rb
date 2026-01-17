require 'pact/consumer_contract/query'

module Pact
  module Consumer

    module RackRequestHelper
      REQUEST_KEYS = {
        'REQUEST_METHOD' => :method,
        'PATH_INFO' => :path,
        'QUERY_STRING' => :query,
        'rack.input' => :body
      }

      def params_hash env
        Pact::Query.parse_string(env["QUERY_STRING"])
      end

      def request_as_hash_from env
        request = env.inject({}) do |memo, (k, v)|
          request_key = REQUEST_KEYS[k]
          memo[request_key] = v if request_key
          memo
        end

        request[:headers] = headers_from env
        body_string = request[:body]&.read || ""

        if body_string.empty?
          request.delete :body
        else
          body_is_json = request[:headers]['Content-Type'] =~ /json/
          request[:body] =  body_is_json ? JSON.parse(body_string) : body_string
        end
        request[:method] = request[:method].downcase
        request
      end

      private

      def headers_from env
        headers = env.reject{ |key, value| !(key.start_with?("HTTP") || key == 'CONTENT_TYPE' || key == 'CONTENT_LENGTH')}
        dasherized_headers = headers.inject({}) do | hash, header |
          hash[standardise_header(header.first)] = header.last
          hash
        end
        # This header is set in lib/pact/mock_service/server/webrick_request_monkeypatch.rb to allow use to
        # restore the original header names with underscores.
        restore_underscored_header_names(dasherized_headers, (env['X_PACT_UNDERSCORED_HEADER_NAMES'] || '').split(","))
      end

      def standardise_header header
        header.gsub(/^HTTP_/, '').split(/[_-]/).collect{|word| word[0].upcase + word[1..-1].downcase}.join("-")
      end

      def restore_underscored_header_names dasherized_headers, original_header_names
        original_header_names.each_with_object(dasherized_headers) do | original_header_name, headers |
          if headers.key?(standardise_header(original_header_name))
            headers[original_header_name] = headers.delete(standardise_header(original_header_name))
          end
        end
      end
    end
  end
end
