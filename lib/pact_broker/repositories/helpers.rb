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

      def order_ignore_case column_name = :name
        order(Sequel.function(:lower, column_name))
      end

      def mysql?
        Sequel::Model.db.adapter_scheme.to_s =~ /mysql/
      end

      def select_all_qualified
        select(Sequel[model.table_name].*)
      end

      def select_for_subquery column
        if mysql? #stoopid mysql doesn't allow subqueries
          select(column).collect{ | it | it[column] }
        else
          select(column)
        end
      end
    end
  end
end
