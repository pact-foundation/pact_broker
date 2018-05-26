require 'pact_broker/repositories/helpers'
require 'pact_broker/webhooks/latest_triggered_webhook'
require 'pact_broker/tags/tag_with_latest_flag'
require 'pact_broker/logging'
require 'pact_broker/verifications/latest_verification_for_consumer_version_tag'
require 'pact_broker/verifications/latest_verification_for_consumer_and_provider'

module PactBroker
  module Matrix

    class Row < Sequel::Model(:materialized_matrix)

      # Used when using table_print to output query results
      TP_COLS = [ :consumer_version_number, :pact_revision_number, :provider_version_number, :verification_number]

      associate(:one_to_many, :latest_triggered_webhooks, :class => "PactBroker::Webhooks::LatestTriggeredWebhook", primary_key: :pact_publication_id, key: :pact_publication_id)
      associate(:one_to_many, :webhooks, :class => "PactBroker::Webhooks::Webhook", primary_key: [:consumer_id, :provider_id], key: [:consumer_id, :provider_id])
      associate(:one_to_many, :consumer_version_tags, :class => "PactBroker::Tags::TagWithLatestFlag", primary_key: :consumer_version_id, key: :version_id)
      associate(:one_to_many, :provider_version_tags, :class => "PactBroker::Tags::TagWithLatestFlag", primary_key: :provider_version_id, key: :version_id)

      many_to_one :latest_verification_for_consumer_and_provider,
        :class => "PactBroker::Verifications::LatestVerificationForConsumerAndProvider",
        primary_key: [:provider_id, :consumer_id], key: [:provider_id, :consumer_id]

      dataset_module do
        include PactBroker::Repositories::Helpers
        include PactBroker::Logging

        def refresh ids
          logger.debug("Refreshing #{model.table_name} for #{ids}")

          db = model.db
          table_name = model.table_name

          if ids[:pacticipant_id]
            db.transaction do
              db[table_name].where(consumer_id: ids[:pacticipant_id]).or(provider_id: ids[:pacticipant_id]).delete
              new_rows = db[source_view_name].where(consumer_id: ids[:pacticipant_id]).or(provider_id: ids[:pacticipant_id]).distinct
              db[table_name].insert(new_rows)
            end
          elsif ids.any?
            accepted_columns = [:consumer_id, :consumer_name, :provider_id, :provider_name]
            criteria = ids.reject{ |k, v| !accepted_columns.include?(k) }
            db.transaction do
              db[table_name].where(criteria).delete
              db[table_name].insert(db[source_view_name].where(criteria))
            end
          end
        end

        def source_view_name
          model.table_name.to_s.gsub('materialized_', '').to_sym
        end

        def matching_selectors selectors
          if selectors.size == 1
            where_consumer_or_provider_is(selectors.first)
          else
            where_consumer_and_provider_in(selectors)
          end
        end

        def where_consumer_and_provider_in selectors
          where{
            Sequel.&(
              Sequel.|(
                *selectors.collect do |s|
                  if s[:pacticipant_version_id]
                    Sequel.&(consumer_id: s[:pacticipant_id], consumer_version_id: s[:pacticipant_version_id])
                  else
                    Sequel.&(consumer_id: s[:pacticipant_id])
                  end
                end
              ),
              Sequel.|(
                *(selectors.collect do |s|
                  if s[:pacticipant_version_id]
                    Sequel.&(provider_id: s[:pacticipant_id], provider_version_id: s[:pacticipant_version_id])
                  else
                    Sequel.&(provider_id: s[:pacticipant_id])
                  end
                end + selectors.collect do |s|
                  Sequel.&(provider_id: s[:pacticipant_id], provider_version_id: nil)
                end)
              )
            )
          }
        end

        def where_consumer_or_provider_is s
          where{
            Sequel.|(
              s[:pacticipant_version_id] ? Sequel.&(consumer_id: s[:pacticipant_id], consumer_version_id: s[:pacticipant_version_id]) :  Sequel.&(consumer_id: s[:pacticipant_id]),
              s[:pacticipant_version_id] ? Sequel.&(provider_id: s[:pacticipant_id], provider_version_id: s[:pacticipant_version_id]) :  Sequel.&(provider_id: s[:pacticipant_id])
            )
          }
        end

        def order_by_names_ascending_most_recent_first
          order(
            Sequel.asc(:consumer_name),
            Sequel.desc(:consumer_version_order),
            Sequel.desc(:pact_revision_number),
            Sequel.asc(:provider_name),
            Sequel.desc(:provider_version_order),
            Sequel.desc(:verification_id))
        end
      end

      # Temporary method while we transition from returning Hashes to return Matrix objects
      # from the repository find methods
      # Need to make the object act as a hash and an object
      def [] key
        if key == :provider_version_tags || key == :consumer_version_tags
          send(key)
        else
          super
        end
      end

      def summary
        "#{consumer_name}#{consumer_version_number} #{provider_name}#{provider_version_number || '?'} (r#{pact_revision_number}n#{verification_number || '?'})"
      end

      def consumer
        @consumer ||= OpenStruct.new(name: consumer_name, id: consumer_id)
      end

      def provider
        @provider ||= OpenStruct.new(name: provider_name, id: provider_id)
      end

      def consumer_version
        @consumer_version ||= OpenStruct.new(number: consumer_version_number, order: consumer_version_order, id: consumer_version_id, pacticipant: consumer)
      end

      def provider_version
        if provider_version_number
          @provider_version ||= OpenStruct.new(number: provider_version_number, order: provider_version_order, id: provider_version_id, pacticipant: provider)
        end
      end

      def pact
        @pact ||= OpenStruct.new(
          consumer: consumer,
          provider: provider,
          consumer_version: consumer_version,
          consumer_version_number: consumer_version_number,
          created_at: pact_created_at,
          revision_number: pact_revision_number,
          pact_version_sha: pact_version_sha
        )
      end

      def verification
        if verification_executed_at
          @latest_verification ||= OpenStruct.new(
            id: verification_id,
            success: success,
            number: verification_number,
            execution_date: verification_executed_at,
            created_at: verification_executed_at,
            provider_version_number: provider_version_number,
            provider_version_order: provider_version_order,
            build_url: verification_build_url,
            provider_version: provider_version,
            consumer_name: consumer_name,
            provider_name: provider_name,
            pact_version_sha: pact_version_sha
          )
        end
      end

      # Add logic for ignoring case
      def <=> other
        comparisons = [
          compare_name_asc(consumer_name, other.consumer_name),
          compare_number_desc(consumer_version_order, other.consumer_version_order),
          compare_number_desc(pact_revision_number, other.pact_revision_number),
          compare_name_asc(provider_name, other.provider_name),
          compare_number_desc(provider_version_order, other.provider_version_order),
          compare_number_desc(verification_id, other.verification_id)
        ]

        comparisons.find{|c| c != 0 } || 0
      end

      def compare_name_asc name1, name2
        name1 <=> name2
      end

      def to_s
        "#{consumer_name} v#{consumer_version_number} #{provider_name} #{provider_version_number} #{success}"
      end

      def compare_number_desc number1, number2
        if number1 && number2
          number2 <=> number1
        elsif number1
          1
        else
          -1
        end
      end

      # For some reason, with MySQL, the success column value
      # comes back as an integer rather than a boolean
      # for the latest_matrix view (but not the matrix view!)
      # Maybe something to do with the union?
      # Haven't investigated as this is an easy enough fix.
      def success
        value = super
        value.nil? ? nil : value == true || value == 1
      end

      def values
        super.merge(success: success)
      end

      # Need to overwrite eql? from lib/sequel/model/base.rb
      # because it uses @values instead of self.values
      # so the success boolean/integer problem mentioned above
      # screws things up
      def eql?(obj)
        (obj.class == model) && (obj.values == values)
      end
    end
  end
end
