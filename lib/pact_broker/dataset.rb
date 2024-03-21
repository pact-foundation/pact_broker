require "sequel"
require "pact_broker/dataset/page"

Sequel.extension :escaped_like

module PactBroker
  module Dataset
    module Helpers
      extend self

      def mysql?
        Sequel::Model.db.adapter_scheme.to_s =~ /mysql/
      end

      def postgres?
        Sequel::Model.db.adapter_scheme.to_s =~ /postgres/
      end

      def escape_wildcards(value)
        value.gsub("_", "\\_").gsub("%", "\\%")
      end
    end

    include Helpers

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

    def where_name_like(column_name, value)
      where(name_like(column_name, value))
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

    # Executes a SELECT query FOR UPDATE, with SKIP LOCKED if supported (postgres only).
    # With FOR UPDATE SKIP LOCKED, the SELECT will run immediately, not waiting for any other transactions,
    # and only return rows that are not already locked by another transaction.
    # The FOR UPDATE is required to make it work this way - SKIP LOCKED on its own does not work.
    def for_update_skip_locked_if_supported
      if supports_skip_locked?
        for_update.skip_locked
      else
        self
      end
    end
  end
end

module Sequel
  # For matching identifying names based on the :use_case_sensitive_resource_names config setting.
  # This has been used inconsistently, and in the next major version, support for case insensitive names will be dropped.
  def self.name_like(column_name, value)
    if PactBroker.configuration.use_case_sensitive_resource_names
      if PactBroker::Dataset::Helpers.mysql?
        # sigh, mysql, this is the only way to perform a case sensitive search
        Sequel.like(column_name, PactBroker::Dataset::Helpers.escape_wildcards(value), { case_insensitive: false })
      else
        { column_name => value }
      end
    else
      Sequel.like(column_name, PactBroker::Dataset::Helpers.escape_wildcards(value), { case_insensitive: true })
    end
  end
end
