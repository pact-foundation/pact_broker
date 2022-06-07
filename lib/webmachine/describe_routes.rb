require "webmachine/adapters/rack_mapped"

module Webmachine
  class DescribeRoutes

    Route = Struct.new(
        :path,
        :path_spec,
        :resource_class,
        :resource_name,
        :resource_class_location,
        :allowed_methods,
        :policy_class,
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

      def build_resource(http_method, application_context, potential_params)
        path_params = route_param_names.each_with_object({}){ | name, new_params | new_params[name] = potential_params[name] }

        path_info = {
          application_context: application_context,
          resource_name: resource_name
        }.merge(path_params)

        dummy_request = Webmachine::Adapters::Rack::RackRequest.new(http_method, "/", Webmachine::Headers["host" => "example.org"], nil, {}, {}, { "REQUEST_METHOD" => http_method })
        dummy_request.path_info = path_info
        dummy_resource = resource_class.new(dummy_request, Webmachine::Response.new)
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
        }.merge(info_from_resource_instance(webmachine_route)))
      end.reject{ | route | route.resource_class == Webmachine::Trace::TraceResource }
    end

    def self.info_from_resource_instance(webmachine_route)
      with_no_logging do
        path_info = { application_context: OpenStruct.new, pacticipant_name: "foo", pacticipant_version_number: "1", resource_name: "foo" }
        path_info.default = "1"
        dummy_request = Webmachine::Adapters::Rack::RackRequest.new("GET", "/", Webmachine::Headers["host" => "example.org"], nil, {}, {}, { "REQUEST_METHOD" => "GET" })
        dummy_request.path_info = path_info
        dummy_resource = webmachine_route.resource.new(dummy_request, Webmachine::Response.new)
        if dummy_resource
          {
            allowed_methods: dummy_resource.allowed_methods,
          }
        else
          {}
        end
      end
    rescue StandardError => e
      puts "Could not determine instance info for #{route.resource}. #{e.class} - #{e.message}"
      {}
    end

    def self.source_location_for(clazz)
      first_instance_method_name = (clazz.instance_methods(false) + clazz.private_instance_methods(false)).first
      clazz.instance_method(first_instance_method_name).source_location.first
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
