require 'pact/mock_service/control_server/app'
require 'pact/mock_service/server/webrick_request_monkeypatch'
require 'rack/handler/webbrick'

module Pact
  module MockService
    module ControlServer
      class Run

        def self.call options
          new(options).call
        end

        def initialize options
          @options = options
        end

        def call
          trap(:INT) { shutdown }
          trap(:TERM) { shutdown }

          # https://github.com/rack/rack/blob/ae78184e5c1fcf4ac133171ed4b47b0548cd9b44/lib/rack/handler/webrick.rb#L32
          # Rack adapter for webrick uses class variable for the server which contains the port,
          # so if we use it more than once in the same process, we lose the reference to the first
          # server, and can't shut it down. So, keep a manual reference to the Webrick server, and
          # shut it down directly rather than use Rack::Handler::WEBrick.shutdown
          # Ruby!
          Rack::Handler::WEBrick.run(control_server, **webbrick_opts) do | server |
            @webrick_server = server
          end
        end

        private

        attr_reader :options

        def control_server
          @control_server ||= Pact::MockService::ControlServer::App.new control_server_options
        end

        def shutdown
          unless @shutting_down
            @shutting_down = true
            begin
              @control_server.shutdown
            ensure
              @webrick_server.shutdown
            end
          end
        end

        def control_server_options
          {
            log_dir: options[:log_dir] || "log",
            pact_dir: options[:pact_dir] || ".",
            unique_pact_file_names: options[:unique_pact_file_names],
            cors_enabled: options[:cors] || false,
            ssl: options[:ssl],
            host: options[:host],
            pact_specification_version: options[:pact_specification_version]
          }
        end

        def webbrick_opts
          {
            :Port => options[:port],
            :Host => options[:host],
            :AccessLog => []
          }
        end
      end
    end
  end
end
