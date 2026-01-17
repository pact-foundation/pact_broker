require 'socket'

# Provides a utility to find an available TCP port on the local machine.
module FindAPort
  # Returns an available port number on the local machine
  #
  # This uses a hack where we create a `TCPServer` and allow Ruby to
  # auto-bind an available port, ask for that port number, and then
  # close the server. There is a small chance that something could bind
  # to that port before you use it; this operation does nothing to
  # *reserve* the port for you.
  #
  # @return [Integer] an available TCP port number
  def available_port
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
  end

  module_function :available_port
end
