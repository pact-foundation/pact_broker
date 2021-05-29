module PactBroker
  module Tags
    module EagerLoaders
      class HeadTag
        def self.call(eo, **_other)
          initialize_association(eo[:rows])
          populate_associations(eo[:rows])
        end

        def self.initialize_association(tags)
          tags.each{|tag| tag.associations[:head_tag] = nil }
        end

        def self.populate_associations(tags)
          group_by_pacticipant_id(tags).each do | pacticipant_id, participant_tags |
            populate_associations_by_pacticipant(pacticipant_id, participant_tags)
          end
        end

        def self.group_by_pacticipant_id(tags)
          tags.to_a.group_by(&:pacticipant_id)
        end

        def self.populate_associations_by_pacticipant(pacticipant_id, tags)
          latest_tags_for_tags = latest_tags_for_pacticipant_id(
            pacticipant_id,
            tags.collect(&:name).uniq.compact,
            tags.first.class
          )
          self.populate_tags(tags, latest_tags_for_tags)
        end

        def self.populate_tags(tags, latest_tags_for_tags)
          tags.each do | tag |
            tag.associations[:head_tag] = latest_tags_for_tags[[tag.pacticipant_id, tag.name]]
          end
        end

        def self.latest_tags_for_pacticipant_id(pacticipant_id, tag_names, tag_class)
          tag_class.latest_tags_for_pacticipant_ids_and_tag_names(pacticipant_id, tag_names).each_with_object({}) do | tag, hash |
            hash[[tag.pacticipant_id, tag.name]] = tag
          end
        end
      end
    end
  end
end
