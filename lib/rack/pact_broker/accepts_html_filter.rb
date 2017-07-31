module Rack
  module PactBroker
    class AcceptsHtmlFilter

      def initialize app
        @app = app
      end

      def call env
        if accepts_html_and_not_json_or_csv env
          @app.call(env)
        else
          [404, {},[]]
        end
      end

      def accepts_html_and_not_json_or_csv env
        accept = env['HTTP_ACCEPT'] || ''
        accepts_html(accept) && !accepts_json_or_csv(accept)
      end

      def accepts_html(accept)
        accept.include?("html")
      end

      def accepts_json_or_csv accept
        accept.include?("json") || accept.include?("csv")
      end
    end
  end
end
