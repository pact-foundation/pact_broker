# Decides whether this is a request for the UI or a request for the API

module Rack
  module PactBroker
    class UIRequestFilter
      def initialize app
        @app = app
      end

      def call env
        if request_for_ui_resource? env
          @app.call(env)
        else
          [404, {},[]]
        end
      end

      private

      def request_for_ui_resource? env
        request_for_file?(env) || accepts_html?(env)
      end

      def request_for_file?(env)
        if last_segment = env['PATH_INFO'].split("/").last
          last_segment.include?(".")
        else
          false
        end
      end

      def accepts_html?(env)
        (env['HTTP_ACCEPT'] || '').include?("text/html")
      end
    end
  end
end
