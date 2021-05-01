require 'pact_broker/hash_refinements'
require 'pact_broker/string_refinements'

module PactBroker
  module RackHelpers
    using PactBroker::HashRefinements
    using PactBroker::StringRefinements

    def determinate_headers(headers)
      headers.without("Date", "Server")
    end

    def rack_env_to_http_headers(rack_env)
      rack_env.each_with_object({}) do |(name, value), converted_headers|
        env_key = name.gsub(/^HTTP_/, '').split('_').collect{ |w| w.downcase.camelcase(true) }.join("-")
        converted_headers[env_key] = value
      end
    end
  end
end
