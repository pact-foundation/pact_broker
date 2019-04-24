require 'webmachine/request'
require 'webmachine/adapters/rack'

# Monkey patch to make the Rack env available on the Webmachine Request object

module Webmachine
  class RackRequest < Webmachine::Request
    attr_reader :env

    def initialize(method, uri, headers, body, routing_tokens, base_uri, env)
      super(method, uri, headers, body, routing_tokens, base_uri)
      @env = env
    end
  end
end


unless Webmachine::Adapters::Rack.private_instance_methods.include?(:build_webmachine_request)
  raise "Webmachine::Adapters::Rack no longer has the private instance method #build_webmachine_request - rack env monkey patch won't work"
end

module Webmachine
  module Adapters
    class Rack < Adapter
      private

      def build_webmachine_request(rack_req, headers)
        Webmachine::RackRequest.new(rack_req.request_method,
                                rack_req.url,
                                headers,
                                RequestBody.new(rack_req),
                                routing_tokens(rack_req),
                                base_uri(rack_req),
                                rack_req.env
                               )
      end
    end
  end
end
