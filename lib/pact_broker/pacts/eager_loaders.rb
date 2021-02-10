module PactBroker
  module Pacts
    module EagerLoaders
      class HeadPactPublicationsForTags
        def self.call(eo)
          pact_publications = eo[:rows]
          initialize_association(pact_publications)
          populate_associations(group_by_consumer_and_provider_ids(pact_publications))
        end

        def self.initialize_association(pact_publications)
          pact_publications.each { |pp| pp.associations[:head_pact_publications_for_tags] = [] }
        end

        def self.group_by_consumer_and_provider_ids(pact_publications)
          pact_publications.group_by{ |pact_publication| [pact_publication.consumer_id, pact_publication.provider_id] }
        end

        def self.populate_associations(grouped_pact_publications)
          grouped_pact_publications.each do | key, pact_publications |
            populate_associations_for_consumer_and_provider(key, pact_publications)
          end
        end

        def self.populate_associations_for_consumer_and_provider(key, pact_publications)
          head_pact_publications_by_tag = hash_of_head_pact_publications(
            pact_publications.first.class,
            pact_publications.first.consumer,
            pact_publications.first.provider,
            pact_publications.flat_map{ |pp| pp.consumer_version_tags.collect(&:name) }
          )

          pact_publications.each do | pact_publication |
            pact_publication.consumer_version_tags.collect(&:name).sort.each do | tag_name |
              pact_publication.associations[:head_pact_publications_for_tags] << head_pact_publications_by_tag[tag_name]
            end
          end
        end

        def self.hash_of_head_pact_publications pact_publication_class, consumer, provider, tag_names
          pact_publication_class
            .for_consumer(consumer)
            .for_provider(provider)
            .latest_for_consumer_tag(tag_names)
            .each_with_object({}) do | head_pact_publication, hash |
              hash[head_pact_publication.values.fetch(:tag_name)] = head_pact_publication
            end
        end
      end
    end
  end
end
