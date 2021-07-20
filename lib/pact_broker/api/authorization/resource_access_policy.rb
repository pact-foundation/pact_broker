require "pact_broker/api/authorization/resource_access_rules"

module PactBroker
  module Api
    module Authorization
      class ResourceAccessPolicy
        READ_METHODS                = %w{GET OPTIONS HEAD}.freeze
        ALL_METHODS                 = %w{GET POST PUT PATCH DELETE HEAD OPTIONS}.freeze
        POST                        = "POST".freeze

        ALL_PATHS                   = %r{.*}.freeze
        PACT_BADGE_PATH             = %r{^/pacts/provider/[^/]+/consumer/.*/badge(?:\.[A-Za-z]+)?$}.freeze
        MATRIX_BADGE_PATH           = %r{^/matrix/provider/[^/]+/latest/[^/]+/consumer/[^/]+/latest/[^/]+/badge(?:\.[A-Za-z]+)?$}.freeze
        HEARTBEAT_PATH              = %r{^/diagnostic/status/heartbeat$}.freeze
        PACTS_FOR_VERIFICATION_PATH = %r{^/pacts/provider/[^/]+/for-verification$}.freeze

        PUBLIC = 0
        READ = 1
        WRITE = 2

        def initialize(resource_access_rules)
          @resource_access_rules = resource_access_rules
        end

        def public_access_allowed?(env)
          resource_access_rules.access_allowed?(env, PUBLIC)
        end

        def read_access_allowed?(env)
          resource_access_rules.access_allowed?(env, READ)
        end

        def self.build(allow_public_read_access, allow_public_access_to_heartbeat)
          rules = [
            [WRITE, ALL_METHODS, ALL_PATHS],
            [READ, READ_METHODS, ALL_PATHS],
            [READ, [POST], PACTS_FOR_VERIFICATION_PATH],
            [PUBLIC, READ_METHODS, PACT_BADGE_PATH],
            [PUBLIC, READ_METHODS, MATRIX_BADGE_PATH]
          ]

          if allow_public_access_to_heartbeat
            rules.unshift([PUBLIC, READ_METHODS, HEARTBEAT_PATH])
          end

          if allow_public_read_access
            rules.unshift([PUBLIC, READ_METHODS, ALL_PATHS])
            rules.unshift([PUBLIC, [POST], PACTS_FOR_VERIFICATION_PATH])
          end

          ResourceAccessPolicy.new(ResourceAccessRules.new(rules))
        end

        private

        attr_reader :resource_access_rules
      end

    end
  end
end

