require 'pact_broker/configuration'

module PactBroker
  module Domain
    class OrderVersions

      include PactBroker::Logging

      def self.call new_version
        new_version.lock!
        PactBroker::Domain::Version.for_update.where(pacticipant_id: new_version.pacticipant_id).exclude(order: nil).reverse(:order).each do | existing_version |
          if new_version_after_existing_version? new_version, existing_version
            new_version.update(order: existing_version.order + 1)
            break
          else
            existing_version.update(order: existing_version.order + 1)
          end
        end

        if new_version.order.nil?
          new_version.update(order: 0)
        end
      end

      def self.new_version_after_existing_version? new_version, existing_version
        return true if PactBroker.configuration.order_versions_by_date
        return OrderableVersion.new(new_version).after?(OrderableVersion.new(existing_version))
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
          (self <=> other) == 1
        end
      end
    end
  end
end
