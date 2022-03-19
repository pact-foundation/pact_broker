Sequel.extension :escaped_like

module PactBroker
  module Repositories
    module Helpers

      extend self

      def all_forbidding_lazy_load
        all.each{ | row | row.forbid_lazy_load if row.respond_to?(:forbid_lazy_load) }
      end

      def name_like column_name, value
        if PactBroker.configuration.use_case_sensitive_resource_names
          if mysql?
            # sigh, mysql, this is the only way to perform a case sensitive search
            Sequel.like(column_name, value.gsub("_", "\\_"), { case_insensitive: false })
          else
            { column_name => value }
          end
        else
          Sequel.like(column_name, value.gsub("_", "\\_"), { case_insensitive: true })
        end
      end

      def pacticipant_id_for_name pacticipant_name
        Sequel::Model.db[:pacticipants].select(:id).where(name_like(:name, pacticipant_name)).limit(1)
      end

      def order_ignore_case column_name = :name
        order(Sequel.function(:lower, column_name))
      end

      def order_append_ignore_case column_name = :name
        order_append(Sequel.function(:lower, column_name))
      end

      def mysql?
        Sequel::Model.db.adapter_scheme.to_s =~ /mysql/
      end

      def postgres?
        Sequel::Model.db.adapter_scheme.to_s =~ /postgres/
      end

      def select_all_qualified
        select(Sequel[model.table_name].*)
      end

      def select_append_all_qualified
        select_append(Sequel[model.table_name].*)
      end

      def select_for_subquery column
        if mysql? #stoopid mysql doesn't allow you to modify datasets with subqueries
          column_name = column.respond_to?(:alias) ? column.alias : column
          select(column).collect{ | it | it[column_name] }
        else
          select(column)
        end
      end

      def no_columns_selected?
        opts[:select].nil?
      end
    end
  end
end
