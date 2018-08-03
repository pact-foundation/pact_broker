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

      def postgres?
        Sequel::Model.db.adapter_scheme.to_s == "postgres"
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

      # TODO refactor to use proper dataset module
      def upsert table, key, other
        row = key.merge(other)
        if postgres?
          table.insert_conflict(update: other, target: key.keys).insert(row)
        elsif mysql?
          table.on_duplicate_key_update.insert(row)
        else
          # Sqlite
          if table.where(key).count == 0
            table.insert(row)
          else
            table.where(key).update(row)
          end
        end
      end
    end
  end
end
