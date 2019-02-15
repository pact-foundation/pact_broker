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

      def upsert row, key_names, columns_to_update = nil
        if postgres?
          insert_conflict(update: row, target: key_names).insert(row)
        elsif mysql?
          update_cols = columns_to_update || (row.keys - key_names)
          on_duplicate_key_update(*update_cols).insert(row)
        else
          # Sqlite
          key = row.reject{ |k, v| !key_names.include?(k) }
          if where(key).count == 0
            insert(row)
          else
            where(key).update(row)
          end
        end
      end
    end
  end
end
