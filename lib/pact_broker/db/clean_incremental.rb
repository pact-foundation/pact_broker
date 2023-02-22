require "pact_broker/logging"
require "pact_broker/matrix/unresolved_selector"
require "pact_broker/date_helper"
require "pact_broker/db/clean/selector"

module PactBroker
  module DB
    class CleanIncremental
      DEFAULT_KEEP_SELECTORS = [
        PactBroker::DB::Clean::Selector.new(tag: true, latest: true),
        PactBroker::DB::Clean::Selector.new(branch: true, latest: true),
        PactBroker::DB::Clean::Selector.new(latest: true),
        PactBroker::DB::Clean::Selector.new(deployed: true),
        PactBroker::DB::Clean::Selector.new(released: true),
        PactBroker::DB::Clean::Selector.new(max_age: 90)
      ]
      TABLES = [:versions, :pact_publications, :pact_versions, :verifications, :triggered_webhooks, :webhook_executions]

      def self.call database_connection, options = {}
        new(database_connection, options).call
      end

      def initialize database_connection, options = {}
        @db = database_connection
        @options = options
      end

      def call
        require "pact_broker/db/models"

        if dry_run?
          dry_run_results
        else
          execute_clean
        end
      end

      private

      attr_reader :db, :options

      def execute_clean
        db.transaction do
          before_counts = current_counts
          PactBroker::Domain::Version.where(id: versions_to_delete.from_self.select_map(:id)).delete
          delete_orphan_pact_versions
          after_counts = current_counts

          TABLES.each_with_object({}) do | table_name, comparison_counts |
            comparison_counts[table_name.to_s] = {
                                                    "deleted" => before_counts[table_name] - after_counts[table_name],
                                                    "kept" => after_counts[table_name]
                                                  }
          end
        end
      end

      def logger
        options[:logger] || PactBroker.logger
      end

      def keep
        @keep ||= if options[:keep]
                    # Could be a Matrix::UnresolvedSelector from the docker image, convert it
                    options[:keep].collect { | unknown_thing | PactBroker::DB::Clean::Selector.from_hash(unknown_thing.to_hash) }
                  else
                    DEFAULT_KEEP_SELECTORS
                  end
      end

      def limit
        options[:limit] || 1000
      end

      def versions_to_delete(columns = [:id])
        fully_qualified_columns = columns.collect { |col| Sequel[:versions][col] }
        PactBroker::Domain::Version
          .select(*fully_qualified_columns)
          .left_outer_join(version_ids_to_keep, { Sequel[:versions][:id] => Sequel[:keep_versions][:id] }, table_alias: :keep_versions)
          .where(Sequel[:keep_versions][:id] => nil)
          .order(Sequel.asc( Sequel[:versions][:id]))
          .limit(limit)
      end

      def version_ids_to_keep
        @version_ids_to_keep ||=  keep.collect { |selector| PactBroker::Domain::Version.for_selector(selector).select(:id) }.reduce(&:union)
      end

      def current_counts
        TABLES.each_with_object({}) do | table_name, counts |
          counts[table_name] = db[table_name].count
        end
      end

      def dry_run?
        options[:dry_run]
      end

      def delete_orphan_pact_versions
        db[:pact_versions].where(id: orphan_pact_versions).delete
      rescue Sequel::DatabaseError => e
        raise unless e.cause.class.name == "Mysql2::Error"

        ids = orphan_pact_versions.map { |row| row[:id] }
        db[:pact_versions].where(id: ids).delete
      end

      def orphan_pact_versions
        db[:pact_versions]
          .left_join(:pact_publications, Sequel[:pact_publications][:pact_version_id]=> Sequel[:pact_versions][:id])
          .left_join(:verifications, Sequel[:verifications][:pact_version_id]=> Sequel[:pact_versions][:id])
          .select(Sequel[:pact_versions][:id])
          .where(
            Sequel[:pact_publications][:id] => nil,
            Sequel[:verifications][:id] => nil
          )
      end

      def version_info(version)
        {
          "number" => version.number,
          "created" => DateHelper.distance_of_time_in_words(version.created_at, DateTime.now) + " ago",
          "tags" => version.tags.collect(&:name).sort
        }
      end

      def dry_run_results
        to_delete = dry_run_to_delete_by_pacticipant
        to_keep = dry_run_to_keep_by_pacticipant

        kept_per_selector = keep.collect do | selector |
          {
            selector: selector.to_hash,
            count: PactBroker::Domain::Version.for_selector(selector).count
          }
        end

        pacticipant_results = pacticipants.each_with_object({}) do | pacticipant, results |
          results[pacticipant.name] = {
            "toDelete" => to_delete[pacticipant.name] || { "count" => 0 },
            "toKeep" => to_keep[pacticipant.id]
          }
        end

        total_versions_count = PactBroker::Domain::Version.count
        versions_to_keep_count = version_ids_to_keep.count
        versions_to_delete_count = versions_to_delete.count

        {
          "counts" => {
            "totalVersions" => total_versions_count,
            "versionsToDelete" => versions_to_delete_count,
            "versionsNotToKeep" => total_versions_count - versions_to_keep_count,
            "versionsToKeep" => versions_to_keep_count,
            "versionsToKeepBySelector" => kept_per_selector,
          },
          "versionSummary" => pacticipant_results
        }
      end

      def expected_remaining_versions
        PactBroker::Domain::Version
          .left_outer_join(versions_to_delete, { Sequel[:versions][:id] => Sequel[:delete_versions][:id] }, table_alias: :delete_versions )
          .where(Sequel[:delete_versions][:id] => nil)
      end

      # Returns the latest version that will be kept for each pacticipant
      def dry_run_latest_versions_to_keep_by_pacticipant
        latest_undeleted_versions_by_order = expected_remaining_versions
          .select_group(:pacticipant_id)
          .select_append{ max(order).as(latest_order) }

        lv_versions_join = {
          Sequel[:lv][:latest_order] => Sequel[:versions][:order],
          Sequel[:lv][:pacticipant_id] => Sequel[:versions][:pacticipant_id]
        }

        PactBroker::Domain::Version
          .select_all_qualified
          .join(latest_undeleted_versions_by_order, lv_versions_join, { table_alias: :lv })
      end

      # Returns the earliest version that will be kept for each pacticipant
      def dry_run_earliest_versions_to_keep_by_pacticipant
        earliest_undeleted_versions_by_order = expected_remaining_versions
          .select_group(:pacticipant_id)
          .select_append{ min(order).as(first_order) }

        ev_versions_join = {
          Sequel[:lv][:first_order] => Sequel[:versions][:order],
          Sequel[:lv][:pacticipant_id] => Sequel[:versions][:pacticipant_id]
        }

        PactBroker::Domain::Version
          .select_all_qualified
          .join(earliest_undeleted_versions_by_order, ev_versions_join, { table_alias: :lv })
      end

      # Returns Hash of pacticipant name => Hash, where the Hash value contains the count, fromVersion and toVersion
      # that will be deleted.
      # @return Hash
      def dry_run_to_delete_by_pacticipant
        versions_to_delete
          .select(Sequel[:versions].*)
          .all
          .group_by{ | v | v.pacticipant_id }
          .each_with_object({}) do | (_pacticipant_id, versions), hash |
            hash[versions.first.pacticipant.name] = {
              "count" => versions.count,
              "fromVersion" => version_info(versions.first),
              "toVersion" => version_info(versions.last)
            }
          end
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      def dry_run_to_keep_by_pacticipant
        latest_to_keep = dry_run_latest_versions_to_keep_by_pacticipant.eager(:tags).each_with_object({}) do | version, r |
          r[version.pacticipant_id] = {
            "firstVersion" => version_info(version)
          }
        end

        earliest_to_keep = dry_run_earliest_versions_to_keep_by_pacticipant.eager(:tags).each_with_object({}) do | version, r |
          r[version.pacticipant_id] = {
            "latestVersion" => version_info(version)
          }
        end

        counts = counts_to_keep

        pacticipants.collect(&:id).each_with_object({}) do | pacticipant_id, results |
          results[pacticipant_id] = { "count" => counts[pacticipant_id] || 0 }
                      .merge(earliest_to_keep[pacticipant_id] || {})
                      .merge(latest_to_keep[pacticipant_id] || {})
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def counts_to_keep
        expected_remaining_versions
          .select_group(:pacticipant_id)
          .select_append{ count(1).as(count) }
          .as_hash(:pacticipant_id, :count)
      end

      def pacticipants
        @pacticipants ||= PactBroker::Domain::Pacticipant.order_ignore_case(:name).all
      end
    end
  end
end
