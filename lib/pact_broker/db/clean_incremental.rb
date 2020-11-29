require 'pact_broker/logging'
require 'pact_broker/matrix/unresolved_selector'
require 'pact_broker/date_helper'


module PactBroker
  module DB
    class CleanIncremental
      DEFAULT_KEEP_SELECTORS = [
        PactBroker::Matrix::UnresolvedSelector.new(tag: true, latest: true),
        PactBroker::Matrix::UnresolvedSelector.new(latest: true),
        PactBroker::Matrix::UnresolvedSelector.new(max_age: 90)
      ]
      TABLES = [:versions, :pact_publications, :pact_versions, :verifications, :triggered_webhooks, :webhook_executions]

      def self.call database_connection, options = {}
        new(database_connection, options).call
      end

      def initialize database_connection, options = {}
        @db = database_connection
        @options = options
      end

      def logger
        options[:logger] || PactBroker.logger
      end

      def keep
        options[:keep] || DEFAULT_KEEP_SELECTORS
      end

      def limit
        options[:limit] || 1000
      end

      def resolve_ids(query, column_name = :id)
        query.collect { |h| h[column_name] }
      end

      def version_ids_to_delete
        db[:versions].where(id: version_ids_to_keep).invert.limit(limit).order(Sequel.asc(:id))
      end

      def version_ids_to_keep
        @version_ids_to_keep ||= selected_versions_to_keep.reduce(&:union)
      end

      def selected_versions_to_keep
        keep.collect do | selector |
          PactBroker::Domain::Version.select(:id).for_selector(selector)
        end
      end

      def call
        require 'pact_broker/db/models'

        if dry_run?
          dry_run_results
        else
          before_counts = current_counts
          result = PactBroker::Domain::Version.where(id: resolve_ids(version_ids_to_delete)).delete
          delete_orphan_pact_versions
          after_counts = current_counts

          TABLES.each_with_object({}) do | table_name, comparison_counts |
            comparison_counts[table_name.to_s] = { "deleted" => before_counts[table_name] - after_counts[table_name], "kept" => after_counts[table_name] }
          end
        end
      end

      private

      attr_reader :db, :options

      def current_counts
        TABLES.each_with_object({}) do | table_name, counts |
          counts[table_name] = db[table_name].count
        end
      end

      def dry_run?
        options[:dry_run]
      end

      def delete_orphan_pact_versions
        referenced_pact_version_ids = db[:pact_publications].select(:pact_version_id).union(db[:verifications].select(:pact_version_id))
        db[:pact_versions].where(id: referenced_pact_version_ids).invert.delete
      end

      def version_info(version)
        {
          "number" => version.number,
          "created" => DateHelper.distance_of_time_in_words(version.created_at, DateTime.now) + " ago",
          "tags" => version.tags.collect(&:name)
        }
      end

      def dry_run_results
        to_delete = dry_run_to_delete
        to_keep = dry_run_to_keep

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
        versions_to_delete_count = version_ids_to_delete.count

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

      def dry_run_latest_versions_to_keep
        latest_undeleted_versions_by_order = PactBroker::Domain::Version.where(id: version_ids_to_delete.select(:id))
          .invert
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

      def dry_run_earliest_versions_to_keep
        earliest_undeleted_versions_by_order = PactBroker::Domain::Version.where(id: version_ids_to_delete.select(:id))
          .invert
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

      def dry_run_to_delete
        PactBroker::Domain::Version
          .where(id: version_ids_to_delete.select(:id))
          .all
          .group_by{ | v | v.pacticipant_id }
          .each_with_object({}) do | (pacticipant_id, versions), thing |
            thing[versions.first.pacticipant.name] = {
              "count" => versions.count,
              "fromVersion" => version_info(versions.first),
              "toVersion" => version_info(versions.last)
            }
          end
      end

      def dry_run_to_keep
        latest_to_keep = dry_run_latest_versions_to_keep.eager(:tags).each_with_object({}) do | version, r |
          r[version.pacticipant_id] = {
            "firstVersion" => version_info(version)
          }
        end

        earliest_to_keep = dry_run_earliest_versions_to_keep.eager(:tags).each_with_object({}) do | version, r |
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

      def counts_to_keep
        db[:versions].where(id: version_ids_to_delete.select(:id))
          .invert
          .select_group(:pacticipant_id)
          .select_append{ count(1).as(count) }
          .all
          .each_with_object({}) do | row, counts |
            counts[row[:pacticipant_id]] = row[:count]
          end
      end

      def pacticipants
        @pacticipants ||= PactBroker::Domain::Pacticipant.order_ignore_case(:name).all
      end
    end
  end
end
