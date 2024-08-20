require "webmachine/adapters/rack_mapped"
require "pact_broker/string_refinements"

# Code to describe the routes in a Webmachine API, including
# path, resource class, allowed methods, schemas, policy class.
# Used in tests and in the pact_broker:routes task

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
        :policy_names,
        :policy_classes, # only used by pactflow
        :schemas,
        keyword_init: true) do

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
        request = Webmachine::Adapters::Rack::RackRequest.new(
          rack_req.env["REQUEST_METHOD"],
          path,
          Webmachine::Headers.from_cgi({"HTTP_HOST" => "example.org"}.merge(env)),
          Webmachine::Adapters::Rack::RequestBody.new(rack_req),
          {},
          {},
          rack_req.env
        )
        request.path_info = path_info
        resource_class.new(request, Webmachine::Response.new)
      end
    end

    def self.call(webmachine_applications, search_term: nil)
      path_mappings = webmachine_applications.flat_map { | webmachine_application | build_routes(webmachine_application) }

      if search_term
        path_mappings = path_mappings.select{ |(route, _)| route[:path].include?(search_term) }
      end

      path_mappings.sort_by{ | mapping | mapping[:path] }
    end

    # Build a Route object to describe every Webmachine route defined in the app.routes block
    # @return [Array<Webmachine::DescribeRoutes::Route>]
    def self.build_routes(webmachine_application)
      webmachine_routes_to_describe(webmachine_application).collect do | webmachine_route |
        resource_path_absolute = Pathname.new(source_location_for(webmachine_route.resource))
        Route.new({
          path: "/" + webmachine_route.path_spec.collect{ |part| part.is_a?(Symbol) ? ":#{part}" : part  }.join("/"),
          path_spec: webmachine_route.path_spec,
          resource_class: webmachine_route.resource,
          resource_name: webmachine_route.instance_variable_get(:@bindings)[:resource_name],
          resource_class_location: resource_path_absolute.relative_path_from(Pathname.pwd).to_s
        }.merge(properties_for_webmachine_route(webmachine_route, webmachine_application.application_context)))
      end
    end

    def self.webmachine_routes_to_describe(webmachine_application)
      webmachine_application.routes.reject{ | route | route.resource == Webmachine::Trace::TraceResource }.collect
    end

    def self.properties_for_webmachine_route(webmachine_route, application_context)
      with_no_logging do
        path_info = { application_context: application_context, pacticipant_name: "foo", pacticipant_version_number: "1", resource_name: "foo" }
        path_info.default = "1"
        request = build_request(http_method: "GET", path_info: path_info)

        resource = webmachine_route.resource.new(request, Webmachine::Response.new)
        if resource
          properties_for_resource(resource.allowed_methods - ["OPTIONS"], webmachine_route, application_context)
        else
          {}
        end
      end
    rescue StandardError => e
      puts "Could not determine instance info for #{webmachine_route.resource}. #{e.class} - #{e.message}"
      {}
    end

    # Return the properties of the resource that can only be determined by instantiating the resource
    # @return [Hash]
    def self.properties_for_resource(allowed_methods, webmachine_route, application_context)
      schemas = []
      policy_names = []
      allowed_methods.each do | http_method |
        resource = build_resource(webmachine_route, http_method, application_context)
        if (schema_class = resource.respond_to?(:schema, true) && resource.send(:schema))
          schemas << { http_method: http_method, class: schema_class, location: source_location_for(schema_class)}
        end

        policy_names << resource.policy_name
      end

      {
        allowed_methods: allowed_methods,
        schemas: schemas,
        policy_names: policy_names.uniq
      }
    end

    def self.build_resource(webmachine_route, http_method, application_context)
      path_info = { application_context: application_context, pacticipant_name: "foo", pacticipant_version_number: "1", resource_name: "foo" }
      path_info.default = "1"
      request = build_request(http_method: http_method, path_info: path_info)
      webmachine_route.resource.new(request, Webmachine::Response.new)
    end

    def self.build_request(http_method: "GET", path_info: )
      request = Webmachine::Adapters::Rack::RackRequest.new(http_method, "/", Webmachine::Headers["host" => "example.org"], nil, {}, {}, { "REQUEST_METHOD" => http_method })
      request.path_info = path_info
      request
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
