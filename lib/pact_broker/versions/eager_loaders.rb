module PactBroker
  module Versions
    module EagerLoaders
      class LatestVersionForBranch
        def self.call(eo, **other)
          initialize_association(eo[:rows])
          populate_associations(eo[:rows])
        end

        def self.initialize_association(versions)
          versions.each{|version| version.associations[:latest_version_for_branch] = nil }
        end

        def self.populate_associations(versions)
          group_by_pacticipant(versions).each do | pacticipant, versions |
            populate_associations_by_pacticipant(pacticipant, versions)
          end
        end

        def self.group_by_pacticipant(versions)
          versions.to_a.group_by(&:pacticipant)
        end

        def self.populate_associations_by_pacticipant(pacticipant, versions)
          latest_versions_for_branches = latest_versions_for_pacticipant_branches(
            pacticipant,
            versions.collect(&:branch).uniq.compact,
            versions.first.class
          )
          self.populate_versions_with_branches(versions, latest_versions_for_branches)
        end

        def self.populate_versions_with_branches(versions, latest_versions_for_branches)
          versions.select(&:branch).each do | version |
            version.associations[:latest_version_for_branch] = latest_versions_for_branches[[version.pacticipant_id, version.branch]]
          end
        end

        def self.latest_versions_for_pacticipant_branches(pacticipant, branches, version_class)
          version_class.latest_versions_for_pacticipant_branches(pacticipant, branches).each_with_object({}) do | row, hash |
            hash[[row.pacticipant_id, row.branch]] = row
          end
        end
      end

      class LatestVersionForPacticipant
        def self.call(eo, **other)
          populate_associations(eo[:rows])
        end

        def self.populate_associations(versions)
          group_by_pacticipant(versions).each do | pacticipant, versions |
            populate_associations_by_pacticipant(pacticipant, versions)
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
