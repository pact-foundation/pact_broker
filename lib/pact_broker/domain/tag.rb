require 'pact_broker/db'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Domain
    class Tag < Sequel::Model
      plugin :timestamps, update_on_create: true
      plugin :insert_ignore, identifying_columns: [:name, :version_id]

      unrestrict_primary_key
      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      dataset_module do
        include PactBroker::Repositories::Helpers

        # Does NOT care about whether or not there is a pact publication
        # for the version
        def latest_tags_for_pacticipant_ids(pacticipant_ids)
          tags_versions_join = {
            Sequel[:tags][:version_id] => Sequel[:versions][:id],
            Sequel[:versions][:pacticipant_id] => pacticipant_ids
          }

          latest_tags_versions_join = {
            Sequel[:latest_tags][:name] => Sequel[:tags][:name],
            Sequel[:latest_tags][:latest_order] => Sequel[:versions][:order],
            Sequel[:latest_tags][:pacticipant_id] => Sequel[:versions][:pacticipant_id],
            Sequel[:versions][:pacticipant_id] => pacticipant_ids
          }

          latest_tags = PactBroker::Domain::Tag
            .select_group(Sequel[:tags][:name], Sequel[:versions][:pacticipant_id])
            .select_append{ max(order).as(latest_order) }
            .join(:versions, tags_versions_join)

          PactBroker::Domain::Tag
            .select_all_qualified
            .join(:versions,
              { Sequel[:tags][:version_id] => Sequel[:versions][:id],
                Sequel[:versions][:pacticipant_id] => pacticipant_ids
              })
            .join(latest_tags, latest_tags_versions_join, { table_alias: :latest_tags })
        end

        def head_tags_for_consumer_id(consumer_id)
          lp = :latest_pact_publication_ids_for_consumer_versions
          tags_versions_join = {
            Sequel[:tags][:version_id] => Sequel[:versions][:id],
            Sequel[:versions][:pacticipant_id] => consumer_id
          }

          versions_pact_publications_join = {
            Sequel[:versions][:id] => Sequel[lp][:consumer_version_id],
            Sequel[lp][:consumer_id] => consumer_id
          }
          # head tags for this consumer
          # the latest tag, pacticipant_id, version order
          # for versions that have a pact publication
          PactBroker::Domain::Tag
            .select_group(Sequel[:tags][:name], Sequel[:versions][:pacticipant_id])
            .select_append{ max(order).as(latest_consumer_version_order) }
            .join(:versions, tags_versions_join)
            .join(lp, versions_pact_publications_join)
        end

        def head_tags_for_pact_publication(pact_publication)
          head_tags_versions_join = {
            Sequel[:head_tags][:latest_consumer_version_order] => Sequel[:versions][:order],
            Sequel[:head_tags][:pacticipant_id] => Sequel[:versions][:pacticipant_id],
            Sequel[:versions][:pacticipant_id] => pact_publication.consumer_id
          }

          # Find the head tags that belong to this pact publication
          # Note: The tag model has the name and version_id,
          # but does not have the created_at value set - but don't need it for now
          head_tags_for_consumer_id(pact_publication.consumer_id).from_self(alias: :head_tags)
            .select(Sequel[:head_tags][:name], Sequel[:versions][:id].as(:version_id))
            .join(:versions, head_tags_versions_join)
            .where(Sequel[:versions][:id] => pact_publication.consumer_version_id)
        end
      end

      def <=> other
        name <=> other.name
      end
    end
  end
end

# Table: tags
# Primary Key: (name, version_id)
# Columns:
#  name       | text                        |
#  version_id | integer                     |
#  created_at | timestamp without time zone | NOT NULL
#  updated_at | timestamp without time zone | NOT NULL
# Indexes:
#  tags_pk      | PRIMARY KEY btree (version_id, name)
#  ndx_tag_name | btree (name)
# Foreign key constraints:
#  tags_version_id_fkey | (version_id) REFERENCES versions(id)
