module PactBroker
  module Documentation
    def remove_deprecated_links(thing)
      case thing
      when Hash then remove_deprecated_links_from_hash(thing)
      when Array then thing.collect { |value| remove_deprecated_links(value) }
      else thing
      end
    end

    def remove_deprecated_links_from_hash(body)
      body.each_with_object({}) do | (key, value), new_body |
        if key == "_links"
          links = value.select do | link_key, _value |
            link_key.start_with?("pb:", "self", "next", "previous", "curies")
          end
          new_body["_links"] = links
        else
          new_body[key] = remove_deprecated_links(value)
        end
      end
    end

    def build_approval_name(category, example_name, http_method)
      "docs_#{category}_" + example_name.tr(" ", "_") + "_" + http_method
    end

    def build_path(path_template, parameter_values, custom_parameter_values)
      parameter_values.merge(custom_parameter_values).inject(path_template) do | new_path, (name, value) |
        new_path.gsub(/:#{name}(\/|$)/, value + '\1')
      end
    end

    def expected_interaction(response, order)
      response_body = response.headers["Content-Type"]&.include?("json") && response.body && response.body != "" ? remove_deprecated_links(JSON.parse(response.body)) : response.body
      expected_response = {
        status: response.status,
        headers: determinate_headers(response.headers),
        body: response_body
      }
      request = {
        method: http_method,
        path_template: path_template,
        path: path,
        headers: rack_env_to_http_headers(rack_headers.reject{ |k, _| k.start_with?("pactbroker") }),
        body: http_params.is_a?(String) ? JSON.parse(http_params) : nil
      }.compact

      {
        category: category,
        name: pact_broker_example_name,
        order: order,
        request: request,
        response: expected_response
      }
    end

  end
end

RSpec.configure do | config |
  config.include(PactBroker::Documentation)
end