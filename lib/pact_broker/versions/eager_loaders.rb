module PactBroker
  module Versions
    module EagerLoaders
      class LatestVersionForPacticipant
        def self.call(eo, **_other)
          populate_associations(eo[:rows])
        end

        def self.populate_associations(versions)
          group_by_pacticipant(versions).each do | pacticipant, participant_versions |
            populate_associations_by_pacticipant(pacticipant, participant_versions)
          end
        end

        def self.group_by_pacticipant(versions)
          versions.to_a.group_by(&:pacticipant)
        end

        def self.populate_associations_by_pacticipant(pacticipant, versions)
          latest_version = versions.first.class.latest_version_for_pacticipant(pacticipant).single_record

          versions.each do | version |
            version.associations[:latest_version_for_pacticipant] = latest_version
          end
        end
      end
    end
  end
end
