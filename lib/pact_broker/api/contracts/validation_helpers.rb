require "pact_broker/services"
require "pact_broker/string_refinements"
require "pact_broker/configuration"
require "uri"

module PactBroker
  module Api
    module Contracts
      module ValidationHelpers
        extend self
        using PactBroker::StringRefinements

        def multiple_lines?(value)
          value && value.is_a?(String) && value.include?("\n")
        end

        def includes_space?(value)
          value && value.is_a?(String) && value.include?(" ")
        end

        # @return true if there is a value present, and it only contains whitespace
        def blank?(value)
          value&.blank?
        end

        # The tins gem has screwed up the present? method by not using refinements
        # Return true if the object is not nil, and if a String, is not blank.
        # @param [Object]
        def provided?(value)
          if value.is_a?(String)
            value.strip.size > 0
          else
            !value.nil?
          end
        end

        def not_provided?(value)
          !provided?(value)
        end

        def valid_url?(url)
          URI(url)
        rescue URI::InvalidURIError, ArgumentError
          false
        end

        def valid_http_method?(http_method)
          Net::HTTP.const_defined?(http_method.capitalize)
        rescue StandardError
          false
        end

        def pacticipant_with_name_exists?(value)
          PactBroker::Services.pacticipant_service.find_pacticipant_by_name(value)
        end

        def environment_with_name_exists?(value)
          PactBroker::Services.environment_service.find_by_name(value)
        end

        def valid_version_number?(value)
          if PactBroker.configuration.order_versions_by_date
            true
          else
            !!PactBroker.configuration.version_parser.call(value)
          end
        end
      end
    end
  end
end