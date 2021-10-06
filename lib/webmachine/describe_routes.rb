require "webmachine/adapters/rack_mapped"

module Webmachine
  class DescribeRoutes

    def self.call(webmachine_applications, search_term: nil)
      path_mappings = webmachine_applications.flat_map { | webmachine_application | paths_to_resource_class_mappings(webmachine_application) }

      if search_term
        path_mappings = path_mappings.select{ |(route, _)| route[:path].include?(search_term) }
      end

      path_mappings.sort_by{ | mapping | mapping[:path] }
    end

    def self.paths_to_resource_class_mappings(webmachine_application)
      webmachine_application.routes.collect do | route |
        resource_path_absolute = Pathname.new(source_location_for(route.resource))
        {
          path: "/" + route.path_spec.collect{ |part| part.is_a?(Symbol) ? ":#{part}" : part  }.join("/"),
          resource_class: route.resource,
          resource_name: route.instance_variable_get(:@bindings)[:resource_name],
          resource_class_location: resource_path_absolute.relative_path_from(Pathname.pwd).to_s
        }.merge(info_from_resource_instance(route))
      end
    end

    def self.info_from_resource_instance(route)
      with_no_logging do
        path_info = { application_context: OpenStruct.new, pacticipant_name: "foo", pacticipant_version_number: "1", resource_name: "foo" }
        path_info.default = "1"
        dummy_request = Webmachine::Adapters::Rack::RackRequest.new("GET", "/", Webmachine::Headers["host" => "example.org"], nil, {}, {}, { "REQUEST_METHOD" => "GET" })
        dummy_request.path_info = path_info
        dummy_resource = route.resource.new(dummy_request, Webmachine::Response.new)
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
