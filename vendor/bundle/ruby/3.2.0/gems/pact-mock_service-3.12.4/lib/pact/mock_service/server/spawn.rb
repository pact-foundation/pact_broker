require 'pact/mock_service/server/wait_for_server_up'

module Pact
  module MockService
    module Server
      class Spawn

        class PortUnavailableError < StandardError; end

        def self.call pidfile, host, port, ssl = false
          if pidfile.can_start?
            if port_available? host, port
              pid = fork do
                yield
              end
              pidfile.pid = pid
              Process.detach(pid)
              Server::WaitForServerUp.(host, port, {ssl: ssl})
              pidfile.write
            else
              raise PortUnavailableError.new("ERROR: Port #{port} already in use.")
            end
          end
        end

        def self.port_available? host, port
          server = TCPServer.new(host, port)
          true
        rescue
          false
        ensure
          server.close if server
        end
      end
    end
  end
end
