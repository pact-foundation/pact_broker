require 'pact_broker/configuration'

module PactBroker
  module Domain
    class OrderVersions

      include PactBroker::Logging

      # TODO select for update
      def self.call new_version
        PactBroker::Domain::Version.for_update.where(pacticipant_id: new_version.pacticipant_id).all
        latest_version_for_pacticipant = latest_version_for(new_version.pacticipant)

        if new_version_after_previous_latest_version? new_version, latest_version_for_pacticipant
          new_version.update(order: latest_version_for_pacticipant.order + 1)
        else
          reorder_all_versions_for_pacticipant new_version.pacticipant_id
        end
      end

      def self.new_version_after_previous_latest_version? new_version, latest_version_for_pacticipant
        return false unless latest_version_for_pacticipant
        OrderableVersion.new(new_version).after?(OrderableVersion.new(latest_version_for_pacticipant))
      end

      def self.latest_version_for pacticipant
        max_order_for_pacticipant = PactBroker::Domain::Version.where(pacticipant_id: pacticipant.id).exclude(order: nil).max(:order)
        PactBroker::Domain::Version.where(pacticipant_id: pacticipant.id, order: max_order_for_pacticipant).exclude(order: nil).single_record
      end

      def self.reorder_all_versions_for_pacticipant pacticipant_id
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

        def after? other
          (self <=> other) == -1
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
