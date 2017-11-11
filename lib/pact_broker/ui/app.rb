require 'pact_broker/ui/controllers/index'
require 'pact_broker/ui/controllers/groups'
require 'pact_broker/ui/controllers/matrix'
require 'pact_broker/doc/controllers/app'

module PactBroker
  module UI
    class App

      def initialize
        @app = ::Rack::Builder.new {

          map "/ui/relationships" do
            run PactBroker::UI::Controllers::Index
          end

          map "/groups" do
            run PactBroker::UI::Controllers::Groups
          end

          map "/doc" do
            run PactBroker::Doc::Controllers::App
          end

          map "/matrix" do
            run PactBroker::UI::Controllers::Matrix
          end

          map "/" do
            run PactBroker::UI::Controllers::Index
          end
        }
      end

      def call env
        @app.call(env)
      end
    end
  end
end
