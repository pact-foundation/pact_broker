require 'pact_broker/configuration'

module PactBroker
  module Domain
    class OrderVersions

      def self.call pacticipant_id
        orderable_versions = PactBroker::Domain::Version.where(:pacticipant_id => pacticipant_id).all.collect{| version | OrderableVersion.new(version) }
        orderable_versions.sort.each_with_index{ | version, i | version.update_model(i) }
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
          # Sequel will only run the update if the column value has changed, so in 99% of
          # cases, only one update will occur.
          version_model.update(:order => new_order)
        end
      end
    end
  end
end
