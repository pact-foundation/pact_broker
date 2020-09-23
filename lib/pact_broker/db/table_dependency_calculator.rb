module PactBroker
  module DB

    # Returns a list of the tables in the database in the order in which
    # they can be truncated or dropped
    class TableDependencyCalculator

      def self.call connection
        new(connection).call
      end

      def initialize connection
        @connection = connection
      end

      def call
        ordered_table_names = []
        dependencies = @connection
          .tables
          .collect{|it| @connection.foreign_key_list(it)
          .collect{|fk| {from: it, to: fk[:table]} } }
          .flatten
          .uniq
        table_names = @connection.tables - [:schema_migrations, :schema_info]
        check(table_names, dependencies, ordered_table_names)
        ordered_table_names
      end

      def deps_on table_name, deps
        deps.select{ | d| d[:to] == table_name }.collect{ |d| d[:from] }
      end

      def check table_names, deps, ordered_table_names
        return if table_names.size == 0
        remaining_dependencies = deps_on(table_names.first, deps) - ordered_table_names
        if remaining_dependencies.size == 0
          ordered_table_names << table_names.first
          check(table_names[1..-1], deps, ordered_table_names)
        else
          check((remaining_dependencies + table_names).uniq, deps, ordered_table_names)
        end
      end
    end
  end
end
