require 'pact_broker/ui/controllers/index'
require 'pact_broker/ui/controllers/groups'
require 'pact_broker/ui/controllers/matrix'
require 'pact_broker/ui/controllers/error_test'
require 'pact_broker/doc/controllers/app'

module PactBroker
  module UI
    class PathInfoFixer
      PATH_INFO = 'PATH_INFO'.freeze

      def initialize app
        @app = app
      end

      def call env
        env[PATH_INFO] = '/' if env[PATH_INFO] == ''
        @app.call(env)
      end
    end

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
            use PathInfoFixer
            run PactBroker::UI::Controllers::Matrix
          end

          map "/test/error" do
            use PathInfoFixer
            run PactBroker::UI::Controllers::ErrorTest
          end

          map "/" do
            use PathInfoFixer
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
