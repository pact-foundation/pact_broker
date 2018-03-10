require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    # A row for each of the overall latest pacts, and a row for each of the latest tagged pacts
    # Rows with a nil consumer_tag_name are the overall latest
    class HeadRow < Row
      set_dataset(:materialized_head_matrix)

      dataset_module do
        include PactBroker::Repositories::Helpers
        include PactBroker::Logging

        def refresh ids
          return super unless ids[:tag_name]

          logger.debug("Refreshing #{model.table_name} for #{ids}")
          db = model.db
          table_name = model.table_name
          criteria = { consumer_id: ids[:pacticipant_id], consumer_version_tag_name: ids[:tag_name] }
          db.transaction do
            db[table_name].where(criteria).delete
            new_rows = db[source_view_name].where(criteria)
            db[table_name].insert(new_rows)
          end
        end
      end
    end
  end
end
