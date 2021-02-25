module Rack
  module PactBroker
    class SetBaseUrl
      X_FORWARDED_PATTERN = /_X_FORWARDED_/.freeze

      def initialize app, base_urls
        @app = app
        @base_urls = base_urls
      end

      def call(env)
        if env["pactbroker.base_url"]
          app.call(env)
        else
          app.call(env.merge("pactbroker.base_url" => select_matching_base_url(env)))
        end
      end

      private

      attr_reader :app, :base_urls

      def select_matching_base_url(env)
        if base_urls.size > 1
          return matching_base_url_considering_x_forwarded_headers(env) ||
            matching_base_url_not_considering_x_forwarded_headers(env) ||
            default_base_url
        end
        default_base_url
      end

      def default_base_url
        base_urls.first
      end

      def matching_base_url_considering_x_forwarded_headers(env)
        matching_base_url(env)
      end

      def matching_base_url_not_considering_x_forwarded_headers(env)
        matching_base_url(env.reject{ |k, _| k =~ X_FORWARDED_PATTERN} )
      end

      def matching_base_url(env)
        request_base_url = Rack::Request.new(env).base_url
        if base_urls.include?(request_base_url)
          request_base_url
        end
      end
    end
  end
end
