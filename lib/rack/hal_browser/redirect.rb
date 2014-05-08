require 'uri'
require 'rack/request'
require 'rack/static'

module Rack
  module HalBrowser
    class Redirect

      def initialize(app, options = {}, &block)
        @app = app
        @excluded_paths = Array(options[:exclude]) << '/hal-browser'
      end

      def call(env)
        request = Rack::Request.new(env)
        if match?(request)
          return [303, {'Location' => hal_browser_url_from_request(request)}, []]
        end
        Rack::Static.new(@app, :urls => ['/hal-browser'], :root => ::File.expand_path('../../../../vendor', __FILE__)).call(env)
      end

      private

      def match?(request)
        request.get? && prefers_html?(request) && path_not_excluded?(request)
      end

      def prefers_html?(request)
        # TODO: actually follow real HTTP content negotiation rules
        request.env.fetch('HTTP_ACCEPT', '').start_with?('text/html') && request.env.fetch('HTTP_ACCEPT', '').include?('json')
      end

      def path_not_excluded?(request)
        !@excluded_paths.detect{|excluded_path| request.path.start_with?(excluded_path) }
      end

      def hal_browser_url_from_request(request)
        url = URI.parse('/hal-browser/browser.html')
        url.fragment = request.path_info
        url.to_s
      end

    end
  end
end
