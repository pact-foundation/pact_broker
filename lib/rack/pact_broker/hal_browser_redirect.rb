# frozen_string_literal: true
require 'pact_broker/api/paths'
require 'pact_broker/configuration'

module Rack
  module PactBroker
    class HalBrowserRedirect
      include ::PactBroker::Api::Paths

      def initialize(app, options = {}, &block)
        @app = app
      end

      def call(env)
        if redirect?(env)
          return [303, {'Location' => hal_browser_url_from_request(env)}, []]
        else
          app.call(env)
        end
      end

      private

      attr_reader :app

      def redirect?(env)
        is_get_for_html?(env) && is_verification_results_path?(env["PATH_INFO"])
      end

      def is_get_for_html?(env)
        env["REQUEST_METHOD"] == "GET" && env["HTTP_ACCEPT"]&.include?("text/html")
      end

      # Doesn't support non root URLs currently
      def hal_browser_url_from_request(env)
        url = URI.parse("#{env["pactbroker.base_url"]}/hal-browser/browser.html")
        url.fragment = "#{env["pactbroker.base_url"]}#{env["PATH_INFO"]}"
        url.to_s
      end
    end
  end
end
