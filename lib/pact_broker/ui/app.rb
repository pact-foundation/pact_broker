require 'pact_broker/ui'
require 'pact_broker/doc/controllers/app'

module PactBroker
  module UI
    class App

      def initialize
        @app = Rack::Builder.new {

          use HtmlFilter

          map "/ui/relationships" do
            run PactBroker::UI::Controllers::Relationships
          end

          map "/groups" do
            run PactBroker::UI::Controllers::Groups
          end

          map "/doc" do
            run PactBroker::Doc::Controllers::App
          end

          map "/" do
            run RedirectRootToRelationships
          end
        }
      end

      def call env
        @app.call(env)
      end

      class RedirectRootToRelationships

        def self.call env
          # A request for the root path in the browser (not the json index) should
          # redirect to ui/relationships
          if (env['PATH_INFO'].chomp("/") == "")
            [303, {'Location' => 'ui/relationships'},[]]
          else
            [404, {},[]]
          end
        end

      end

      class HtmlFilter

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
          accept.include?("html") && !accept.include?("json") && !accept.include?("csv")
        end

      end

    end
  end

end