Sequel.extension :escaped_like

module PactBroker
  module Repositories
    module Helpers

      extend self

      def name_like column_name, value
        if PactBroker.configuration.use_case_sensitive_resource_names
          if mysql?
            # sigh, mysql, this is the only way to perform a case sensitive search
            Sequel.escaped_like(column_name, value)
          else
            { column_name => value }
          end
        else
          { Sequel.function(:lower, column_name) => value.downcase }
        end
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

      def upsert row, unique_key_names, columns_to_update = nil
        if postgres?
          insert_conflict(update: row, target: unique_key_names).insert(row)
        elsif mysql?
          update_cols = columns_to_update || (row.keys - unique_key_names)
          on_duplicate_key_update(*update_cols).insert(row)
        else
          # Sqlite
          key = row.reject{ |k, v| !unique_key_names.include?(k) }
          if where(key).count == 0
            insert(row)
          else
            where(key).update(row)
          end
        end
        model.where(row.select{ |key, _| unique_key_names.include?(key)}).single_record
      end
    end
  end
end
