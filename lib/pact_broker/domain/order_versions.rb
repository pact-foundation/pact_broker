require 'pact_broker/configuration'

module PactBroker
  module Domain
    class OrderVersions

      include PactBroker::Logging
      # TODO select for update
      def self.call pacticipant_id

        orderable_versions = PactBroker::Domain::Version.for_update.where(:pacticipant_id => pacticipant_id).order(:created_at, :id).collect{| version | OrderableVersion.new(version) }
        ordered_versions = if PactBroker.configuration.order_versions_by_date
          orderable_versions # already ordered in SQL
        else
          orderable_versions.sort
        end
        ordered_versions.each_with_index{ | version, i | version.update_model(i) }
      end

      class OrderableVersion

        attr_accessor :version_model, :sortable_number

        def initialize version_model
          @version_model = version_model
          @sortable_number = PactBroker.configuration.version_parser.call version_model.number
        end

        # Incoming version numbers are rejected if they can't be parsed by the version parser,
        # however, the change from Versionomy to SemVer for version parsing means that some
        # existing version numbers cannot be parsed and are returning nil.
        # The main reason to sort the versions is to that we can get the "latest" pact.
        # Any existing version with a number that cannot be parsed will almost definitely not
        # be the "latest", so sort them first.
        def <=> other
          if sortable_number.nil? && other.sortable_number.nil?
            0
          elsif sortable_number.nil?
            -1
          elsif other.sortable_number.nil?
            1
          else
            self.sortable_number <=> other.sortable_number
          end
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
