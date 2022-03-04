require "pact_broker/api/authorization/resource_access_rules"
require "pact_broker/api/paths"

module PactBroker
  module Api
    module Authorization
      class ResourceAccessPolicy
        include PactBroker::Api::Paths

        READ_METHODS                = %w{GET OPTIONS HEAD}.freeze
        ALL_METHODS                 = %w{GET POST PUT PATCH DELETE HEAD OPTIONS}.freeze
        POST                        = "POST".freeze
        ALL_PATHS                   = %r{.*}.freeze
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

        def self.build(allow_public_read_access, allow_public_access_to_heartbeat, enable_public_badge_access)
          rules = [
            [WRITE, ALL_METHODS, ALL_PATHS],
            [READ, READ_METHODS, ALL_PATHS],
            [READ, [POST], PACTS_FOR_VERIFICATION_PATH],
          ]

          if enable_public_badge_access
            rules.concat(BADGE_PATHS.collect { | badge_path | [PUBLIC, READ_METHODS, badge_path] })
          end

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

