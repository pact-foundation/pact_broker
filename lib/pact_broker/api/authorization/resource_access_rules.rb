require "rack"

module PactBroker
  module Api
    module Authorization
      class ResourceAccessRules
        PATH_INFO = Rack::PATH_INFO
        REQUEST_METHOD = Rack::REQUEST_METHOD

        def initialize(rules)
          @rules = rules
        end

        def access_allowed?(env, level)
          !!rules.find do | rule_level, allowed_methods, path_pattern |
            level_allowed?(level, rule_level) &&
              method_allowed?(env, allowed_methods) &&
              path_allowed?(env, path_pattern)
          end
        end

        private

        attr_reader :rules

        def level_allowed?(level, rule_level)
          level >= rule_level
        end

        def path_allowed?(env, pattern)
          env[PATH_INFO] =~ pattern
        end

        def method_allowed?(env, allowed_methods)
          allowed_methods.include?(env[REQUEST_METHOD])
        end
      end
    end
  end
end
