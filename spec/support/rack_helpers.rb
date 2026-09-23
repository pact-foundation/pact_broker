require "pact_broker/string_refinements"

module PactBroker
  module RackHelpers
    using PactBroker::StringRefinements

    # Rack 3 emits downcased response header names, so match case insensitively.
    NON_DETERMINATE_HEADERS = ["date", "server", "content-length"].freeze

    def determinate_headers(headers)
      headers.reject { |name, _| NON_DETERMINATE_HEADERS.include?(name.downcase) }
    end

    def rack_env_to_http_headers(rack_env)
      rack_env.each_with_object({}) do |(name, value), converted_headers|
        env_key = name.gsub(/^HTTP_/, "").split("_").collect{ |w| w.downcase.camelcase(true) }.join("-")
        converted_headers[env_key] = value
      end
    end
  end
end
