require "webmachine/adapters/rack_mapped"
require "pact_broker/string_refinements"

module Webmachine
  class DescribeRoutes
    using PactBroker::StringRefinements

    Route = Struct.new(
        :path,
        :path_spec,
        :resource_class,
        :resource_name,
        :resource_class_location,
        :allowed_methods,
        :policy_class,
        :schemas,
        keyword_init: true) do

      def [](key)
        if respond_to?(key)
          send(key)
        else
          nil
        end
      end

      def path_include?(component)
        path.include?(component)
      end

      def route_param_names
        path_spec.select { | component | component.is_a?(Symbol) }
      end

      # Creates a Webmachine Resource for the given route for use in tests.
      # @param [Hash] env the rack env from which to build the request
      # @param [PactBroker::ApplicationContext] application_context the application context
      # @param [Hash] path_param_values concrete parameter values from which to construct the path
      # @return [Webmachine::Resource] the webmachine resource for the request
      def build_resource(env, application_context, path_param_values)
        path = "/" + path_spec.collect{ | part | part.is_a?(Symbol) ? (path_param_values[part] || "missing-param") : part }.join("/")

        path_params = route_param_names.each_with_object({}){ | name, new_params | new_params[name] = path_param_values[name] }
        path_info = {
          application_context: application_context,
          resource_name: resource_name
        }.merge(path_params)

        rack_req = ::Rack::Request.new({ "REQUEST_METHOD" => "GET", "rack.input" => StringIO.new("") }.merge(env) )
        dummy_request = Webmachine::Adapters::Rack::RackRequest.new(
          rack_req.env["REQUEST_METHOD"],
          path,
          Webmachine::Headers.from_cgi({"HTTP_HOST" => "example.org"}.merge(env)),
          Webmachine::Adapters::Rack::RequestBody.new(rack_req),
          {},
          {},
          rack_req.env
        )
        dummy_request.path_info = path_info
        resource_class.new(dummy_request, Webmachine::Response.new)
      end
    end

    def self.call(webmachine_applications, search_term: nil)
      path_mappings = webmachine_applications.flat_map { | webmachine_application | paths_to_resource_class_mappings(webmachine_application) }

      if search_term
        path_mappings = path_mappings.select{ |(route, _)| route[:path].include?(search_term) }
      end

      path_mappings.sort_by{ | mapping | mapping[:path] }
    end

    def self.paths_to_resource_class_mappings(webmachine_application)
      webmachine_application.routes.collect do | webmachine_route |
        resource_path_absolute = Pathname.new(source_location_for(webmachine_route.resource))
        Route.new({
          path: "/" + webmachine_route.path_spec.collect{ |part| part.is_a?(Symbol) ? ":#{part}" : part  }.join("/"),
          path_spec: webmachine_route.path_spec,
          resource_class: webmachine_route.resource,
          resource_name: webmachine_route.instance_variable_get(:@bindings)[:resource_name],
          resource_class_location: resource_path_absolute.relative_path_from(Pathname.pwd).to_s
        }.merge(info_from_resource_instance(webmachine_route, webmachine_application.application_context)))
      end.reject{ | route | route.resource_class == Webmachine::Trace::TraceResource }
    end

    def self.info_from_resource_instance(webmachine_route, application_context)
      with_no_logging do
        path_info = { application_context: application_context, pacticipant_name: "foo", pacticipant_version_number: "1", resource_name: "foo" }
        path_info.default = "1"
        dummy_request = dummy_request(http_method: "GET", path_info: path_info)

        dummy_resource = webmachine_route.resource.new(dummy_request, Webmachine::Response.new)
        if dummy_resource
          info_from_dummy_resource(dummy_resource, webmachine_route, path_info)
        else
          {}
        end
      end
    rescue StandardError => e
      puts "Could not determine instance info for #{webmachine_route.resource}. #{e.class} - #{e.message}"
      {}
    end

    def self.info_from_dummy_resource(dummy_resource, webmachine_route, path_info)
      {
        allowed_methods: dummy_resource.allowed_methods,
        schemas: dummy_resource.respond_to?(:schema, true) && dummy_resource.send(:schema) ? schemas(dummy_resource.allowed_methods, webmachine_route.resource, path_info) : nil
      }.compact
    end

    # This is not entirely accurate, because some GET requests have schemas too, but we can't tell that statically at the moment
    def self.schemas(allowed_methods, resource, path_info)
      (allowed_methods - ["GET", "OPTIONS", "DELETE"]).collect do | http_method |
        resource.new(dummy_request(http_method: http_method, path_info: path_info), Webmachine::Response.new).send(:schema)
      end.uniq.collect do | schema_class |
        {
          class: schema_class,
          location: source_location_for(schema_class)
        }
      end
    end

    def self.dummy_request(http_method: "GET", path_info: )
      dummy_request = Webmachine::Adapters::Rack::RackRequest.new(http_method, "/", Webmachine::Headers["host" => "example.org"], nil, {}, {}, { "REQUEST_METHOD" => http_method })
      dummy_request.path_info = path_info
      dummy_request
    end

    def self.source_location_for(clazz)
      first_instance_method_name = (clazz.instance_methods(false) + clazz.private_instance_methods(false)).first
      if first_instance_method_name
        clazz.instance_method(first_instance_method_name).source_location.first
      else
        # have a guess!
        "lib/" + clazz.name.snakecase.gsub("::", "/") + ".rb"
      end
    end

    # If we don't turn off the logging, we get metrics logging due to the instantiation of the Webmachine::RackRequest class
    def self.with_no_logging
      original_default_level = SemanticLogger.default_level
      SemanticLogger.default_level = :fatal
      yield
    ensure
      SemanticLogger.default_level = original_default_level
    end
  end
end
