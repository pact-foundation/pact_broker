# Taken from https://github.com/webmachine/webmachine-ruby/blob/master/lib/webmachine/adapters/rack.rb

require "webmachine/adapter"
require "rack"
require "webmachine/constants"
require "webmachine/headers"
require "webmachine/request"
require "webmachine/response"
require "webmachine/version"
require "webmachine/chunked_body"

module Webmachine
  module Adapters
    class Rack3 < Adapter
      # Used to override default Rack server options (useful in testing)
      DEFAULT_OPTIONS = {}

      REQUEST_URI = "REQUEST_URI".freeze
      RACK_VERSION = ::Rack::RELEASE.match(/^(\d+\.\d+)/)[1]
      VERSION_STRING = "#{Webmachine::SERVER_STRING} Rack/#{RACK_VERSION}".freeze
      NEWLINE = "\n".freeze

      # Start the Rack adapter
      def run
        options = DEFAULT_OPTIONS.merge({
                                          app: self,
                                          Port: application.configuration.port,
                                          Host: application.configuration.ip
                                        }).merge(application.configuration.adapter_options)

        @server = ::Rack::Server.new(options)
        @server.start
      end

      # Handles a Rack-based request.
      # @param [Hash] env the Rack environment
      def call(env)
        headers = Webmachine::Headers.from_cgi(env)

        rack_req = ::Rack::Request.new env
        request = build_webmachine_request(rack_req, headers)

        response = Webmachine::Response.new
        application.dispatcher.dispatch(request, response)

        response.headers[SERVER] = VERSION_STRING

        rack_status = response.code
        rack_headers = response.headers.flattened(NEWLINE)
        rack_body = case response.body
                    when String # Strings are enumerable in ruby 1.8
                      [response.body]
                    else
                      if (io_body = IO.try_convert(response.body))
                        io_body
                      elsif response.body.respond_to?(:call)
                        Webmachine::ChunkedBody.new(Array(response.body.call))
                      elsif response.body.respond_to?(:each)
                        # This might be an IOEncoder with a Content-Length, which shouldn't be chunked.
                        if response.headers[TRANSFER_ENCODING] == "chunked"
                          Webmachine::ChunkedBody.new(response.body)
                        else
                          response.body
                        end
                      else
                        [response.body.to_s]
                      end
                    end

        rack_res = RackResponse.new(rack_body, rack_status, rack_headers)
        rack_res.finish
      end

      protected

      def routing_tokens(_rack_req)
        nil # no-op for default, un-mapped rack adapter
      end

      def base_uri(_rack_req)
        nil # no-op for default, un-mapped rack adapter
      end

      private

      def build_webmachine_request(rack_req, headers)
        RackRequest.new(rack_req.request_method,
                        rack_req.url,
                        headers,
                        RequestBody.new(rack_req),
                        routing_tokens(rack_req),
                        base_uri(rack_req),
                        rack_req.env)
      end

      class RackRequest < Webmachine::Request
        attr_reader :env

        # Yeah, Rubocop, piss off!
        # rubocop:disable ParameterLists
        def initialize(method, uri, headers, body, routing_tokens, base_uri, env)
          super(method, uri, headers, body, routing_tokens, base_uri)
          @env = env
        end
      end

      class RackResponse
        ONE_FIVE = "1.5".freeze

        def initialize(body, status, headers)
          @body = body
          @status = status
          @headers = headers
        end

        def finish
          @headers[CONTENT_TYPE] ||= TEXT_HTML if rack_release_enforcing_content_type
          @headers.delete(CONTENT_TYPE) if response_without_body
          [@status, @headers, @body]
        end

        protected

        def response_without_body
          ::Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include? @status
        end

        def rack_release_enforcing_content_type
          ::Rack.release < ONE_FIVE
        end
      end

      # Wraps the Rack input so it can be treated like a String or
      # Enumerable.
      # @api private
      class RequestBody
        # @param [Rack::Request] request the Rack request
        def initialize(request)
          @request = request
        end

        # Rack Servers differ in the way you can access their request bodys.
        # While some allow you to directly get a Ruby IO object others don't.
        # You have to check the methods they expose, like #gets, #read, #each, #rewind and maybe others.
        # See: https://github.com/rack/rack/blob/rack-1.5/lib/rack/lint.rb#L296
        # @return [IO] the request body
        def to_io
          @request.body
        end

        # Converts the body to a String so you can work with the entire
        # thing.
        # @return [String] the request body as a string
        def to_s
          if @value
            @value.join
          elsif @request.body.respond_to?(:to_ary)
            @request.body.to_ary.join
          elsif @request.body.respond_to?(:read)
            @request.body.rewind if @request.body.respond_to?(:rewind)
            @request.body.read
          else
            @request.body&.to_s || ""
          end
        end

        # Iterates over the body in chunks. If the body has previously
        # been read, this method can be called again and get the same
        # sequence of chunks.
        # @yield [chunk]
        # @yieldparam [String] chunk a chunk of the request body
        def each
          if @value
            @value.each { |chunk| yield chunk }
          elsif @request.body.respond_to?(:each)
            @value = []
            @request.body.each { |chunk|
              @value << chunk
              yield chunk
            }
          elsif @request.body.respond_to?(:to_ary)
            @value = @request.body.to_ary
            @value.each { |chunk| yield chunk }
          else
            yield @request.body
          end
        end
      end # class RequestBody
    end # class Rack

    class Rack3Mapped < Rack3
      protected

      def routing_tokens(rack_req)
        routing_match = rack_req.path_info.match(Webmachine::Request::ROUTING_PATH_MATCH)
        routing_path = routing_match ? routing_match[1] : ""
        routing_path.split(SLASH)
      end

      def base_uri(rack_req)
        # rack SCRIPT_NAME env var doesn't end with "/". This causes weird
        # behavour when URI.join concatenates URI components in
        # Webmachine::Decision::Flow#n11
        script_name = rack_req.script_name + SLASH
        URI.join(rack_req.base_url, script_name)
      end
    end # class RackMapped

  end # module Adapters
end # module Webmachine
