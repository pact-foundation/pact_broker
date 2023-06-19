require "sequel"
require "pact_broker/dataset/page"

Sequel.extension :escaped_like

module PactBroker
  module Dataset

    # Return a dataset that only includes the rows where the specified column
    # includes the given query string.
    # @return [Sequel::Dataset]
    def filter(column_name, query_string)
      where(Sequel.ilike(column_name, "%" + escape_wildcards(query_string) + "%"))
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

    def select_all_qualified
      select(Sequel[model.table_name].*)
    end

    def all_with_pagination_options(pagination_options)
      if pagination_options&.any?
        query = paginate(pagination_options[:page_number], pagination_options[:page_size])
        Page.new(query.all, query)
      else
        all
      end
    end

    def all_forbidding_lazy_load
      all.each{ | row | row.forbid_lazy_load if row.respond_to?(:forbid_lazy_load) }
    end

    def all_allowing_lazy_load
      all.each{ | row | row.allow_lazy_load if row.respond_to?(:allow_lazy_load) }
    end

    # @param [Symbol] max_column the name of the column of which to calculate the maxiumum
    # @param [Array<Symbol>] group_by_columns the names of the columns by which to group
    def max_group_by(max_column, group_by_columns, &extra_criteria_block)
      maximums_base_query = extra_criteria_block ? extra_criteria_block.call(self) : self
      maximums = maximums_base_query.select_group(*group_by_columns).select_append(Sequel.function(:max, max_column).as(:max_value))

      max_join = group_by_columns.each_with_object({ Sequel[:maximums][:max_value] => max_column }) do | column_name, joins |
        joins[Sequel[:maximums][column_name]] = column_name
      end

      join(maximums, max_join, table_alias: :maximums)
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

    def escape_wildcards(value)
      value.gsub("_", "\\_").gsub("%", "\\%")
    end

    private :escape_wildcards

  end
end
