require "pact_broker/db/data_migrations/helpers"
require "pact_broker/logging"
require "pact_broker/pacts/content"
require "pact_broker/pacts/interactions/types"

module PactBroker
  module DB
    module DataMigrations
      # Sets has_messages, has_http_interactions, messages_count and interactions_count on the
      # pact_versions rows where has_http_interactions is NULL, which are the rows written before
      # the flag existed. The counts follow Interactions::Types: messages_count counts every message,
      # including typed v4 messages, and interactions_count counts the HTTP interactions.
      class SetPactVersionInteractionFlags
        extend PactBroker::DB::DataMigrations::Helpers
        include PactBroker::Logging

        BATCH_SIZE = 500

        def self.call(connection, _options = {})
          return unless nullable_column_present?(connection)

          last_id = 0
          updated = 0
          loop do
            rows = connection[:pact_versions]
              .where(has_http_interactions: nil)
              .where { id > last_id }
              .order(:id)
              .limit(BATCH_SIZE)
              .select(:id, :content)
              .all
            break if rows.empty?

            # Inside a migration transaction, Sequel reuses it and the page commits with the migration.
            connection.transaction { rows.each { |row| set_flags(connection, row) } }
            last_id = rows.last[:id]
            updated += rows.size
            logger.info "Set interaction flags on #{updated} pact versions so far, up to id #{last_id}"
          end

          logger.info "Set interaction flags on #{updated} pact versions" if updated > 0
          nil
        end

        def self.set_flags(connection, row)
          types = types_for(row)
          connection[:pact_versions].where(id: row[:id]).update(
            has_messages: types.has_messages?,
            has_http_interactions: types.has_http_interactions?,
            messages_count: types.message_interactions.count,
            interactions_count: types.http_interactions.count
          )
        end

        # Re-raises a parse failure as the same error class, with the row id in the message.
        def self.types_for(row)
          PactBroker::Pacts::Interactions::Types.for(PactBroker::Pacts::Content.from_json(row[:content]))
        rescue StandardError => e
          raise e.exception("Could not read the content of pact_versions id #{row[:id]}: #{e.message}")
        end

        def self.nullable_column_present?(connection)
          column = column_exists?(connection, :pact_versions, :has_http_interactions)
          column && column.last[:allow_null] != false
        end

        private_class_method :set_flags, :types_for, :nullable_column_present?
      end
    end
  end
end
