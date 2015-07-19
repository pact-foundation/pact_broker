module PactBroker
  module Repositories
    module Helpers

      extend self

      def name_like column_name, value
        Sequel.like(column_name, value, case_sensitivity_options)
      end

      def case_sensitivity_options
        {case_insensitive: !PactBroker.configuration.use_case_sensitive_resource_names}
      end
    end
  end
end
