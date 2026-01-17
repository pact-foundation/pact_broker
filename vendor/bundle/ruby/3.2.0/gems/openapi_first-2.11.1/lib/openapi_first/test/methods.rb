# frozen_string_literal: true

require_relative 'minitest_helpers'
require_relative 'plain_helpers'

module OpenapiFirst
  module Test
    # Methods to use in integration tests
    module Methods
      def self.included(base)
        base.include(DefaultApiMethod)
        base.include(AssertionMethod)
      end

      def self.[](application_under_test = nil, api: nil)
        mod = Module.new do
          def self.included(base)
            base.include OpenapiFirst::Test::Methods::AssertionMethod
          end
        end

        if api
          mod.define_method(:openapi_first_default_api) { api }
        else
          mod.include(DefaultApiMethod)
        end

        if application_under_test
          mod.define_method(:app) { OpenapiFirst::Test.app(application_under_test, api: openapi_first_default_api) }
        end

        mod
      end

      # Default methods
      module DefaultApiMethod
        # This is the default api that is used by assert_api_conform
        # :default is the default name that is used if you don't pass an `api:` option to `OpenapiFirst::Test.register`
        # This is overwritten if you pass an `api:` option to `include OpenapiFirst::Test::Methods[…]`
        def openapi_first_default_api
          klass = self.class
          if klass.respond_to?(:metadata) && klass.metadata[:api]
            klass.metadata[:api]
          else
            :default
          end
        end
      end

      # @visibility private
      module AssertionMethod
        def self.included(base)
          if Test.minitest?(base)
            base.include(OpenapiFirst::Test::MinitestHelpers)
          else
            base.include(OpenapiFirst::Test::PlainHelpers)
          end
        end
      end
    end
  end
end
