
module PactBroker
  module Ui
    class PathInfoFixer
      PATH_INFO = "PATH_INFO".freeze

      def initialize app
        @app = app
      end

      def call env
        env[PATH_INFO] = "/" if env[PATH_INFO] == ""
        @app.call(env)
      end
    end

    class App

      def initialize
        @app = ::Rack::Builder.new do

          map "/ui/relationships" do
            run PactBroker::Ui::Controllers::Index
          end

          map "/pacticipants" do
            run PactBroker::Ui::Controllers::Groups
          end

          map "/doc" do
            run PactBroker::Doc::Controllers::App
          end

          map "/matrix" do
            use PathInfoFixer
            run PactBroker::Ui::Controllers::Matrix
          end

          map "/pacticipants/" do
            use PathInfoFixer
            run PactBroker::Ui::Controllers::CanIDeploy
          end

          map "/pacts/" do
            use PathInfoFixer
            run PactBroker::Ui::Controllers::Pacts
          end

          map "/test/error" do
            use PathInfoFixer
            run PactBroker::Ui::Controllers::ErrorTest
          end

          map "/dashboard" do
            use PathInfoFixer
            run PactBroker::Ui::Controllers::Dashboard
          end

          map "/" do
            use PathInfoFixer
            run PactBroker::Ui::Controllers::Index
          end
        end
      end

      def call env
        @app.call(env)
      end
    end
  end
end
