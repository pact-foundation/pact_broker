require 'pact_broker/configuration'

module PactBroker
  module Domain
    class OrderVersions

      # TODO select for update
      def self.call pacticipant_id
        PactBroker::Domain::Version.db.transaction do
          orderable_versions = PactBroker::Domain::Version.for_update.where(:pacticipant_id => pacticipant_id).order(:created_at, :id).collect{| version | OrderableVersion.new(version) }
          ordered_versions = if PactBroker.configuration.order_versions_by_date
            orderable_versions # already ordered in SQL
          else
            orderable_versions.sort
          end
          ordered_versions.each_with_index{ | version, i | version.update_model(i) }
        end
      end

      class OrderableVersion

        attr_accessor :version_model, :sortable_number

        def initialize version_model
          @version_model = version_model
          @sortable_number = PactBroker.configuration.version_parser.call version_model.number
        end

        def <=> other
          self.sortable_number <=> other.sortable_number
        end

        def update_model new_order
          if version_model.order != new_order
            # Avoid modifying the updated_at flag by doing a manual update
            # In 99% of cases, this will only set the order of the most recent version
            PactBroker::Domain::Version.where(id: version_model.id).update(order: new_order)
          end
        end
      end
    end
  end
end
