require 'pact_broker/db'
require 'pact_broker/repositories/helpers'
require 'pact_broker/tags/eager_loaders'

module PactBroker
  module Domain
    class Tag < Sequel::Model
      plugin :timestamps, update_on_create: true
      plugin :insert_ignore, identifying_columns: [:name, :version_id]

      unrestrict_primary_key
      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      # The tag for the latest version that has a tag with a matching name
      many_to_one :head_tag, read_only: true, key: [:name, :pacticipant_id],
        class: Tag,
        dataset: lambda {
          Tag.where(name: name, pacticipant_id: pacticipant_id)
            .order(Sequel.desc(:version_order))
            .limit(1)
        },
        eager_loader: PactBroker::Tags::EagerLoaders::HeadTag

      dataset_module do
        include PactBroker::Repositories::Helpers

        def join_pact_publications
          join(:pact_publications, { Sequel[:tags][:version_id] => Sequel[:pact_publications][:consumer_version_id] } )
        end

        def for(pacticipant_name, version_number, tag_name)
          where(
            version_id: db[:versions].select(:id).where(
              number: version_number,
              pacticipant_id: db[:pacticipants].select(:id).where(name_like(:name, pacticipant_name))
            ),
            name: tag_name
          ).single_record
        end

        def latest_tags
          self_join = {
            Sequel[:tags][:pacticipant_id] => Sequel[:tags_2][:pacticipant_id],
            Sequel[:tags][:name] => Sequel[:tags_2][:name]
          }

          PactBroker::Domain::Tag
            .select_all_qualified
            .left_join(:tags, self_join, { table_alias: :tags_2 }) do
              Sequel[:tags_2][:version_order] > Sequel[:tags][:version_order]
            end
            .where(Sequel[:tags_2][:name] => nil)
        end

        # Does NOT care about whether or not there is a pact publication
        # for the version
        def latest_tags_for_pacticipant_ids(pacticipant_ids)
          self_join = {
            Sequel[:tags][:pacticipant_id] => Sequel[:tags_2][:pacticipant_id],
            Sequel[:tags][:name] => Sequel[:tags_2][:name],
            Sequel[:tags_2][:pacticipant_id] => pacticipant_ids,
          }

          Tag
            .select_all_qualified
            .left_join(:tags, self_join, { table_alias: :tags_2 }) do
              Sequel[:tags_2][:version_order] > Sequel[:tags][:version_order]
            end
            .where(Sequel[:tags_2][:name] => nil)
            .where(Sequel[:tags][:pacticipant_id] => pacticipant_ids)
        end

        def latest_tags_for_pacticipant_ids_and_tag_names(pacticipant_ids, tag_names)
          self_join = {
            Sequel[:tags][:pacticipant_id] => Sequel[:tags_2][:pacticipant_id],
            Sequel[:tags][:name] => Sequel[:tags_2][:name],
            Sequel[:tags_2][:pacticipant_id] => pacticipant_ids,
            Sequel[:tags_2][:name] => tag_names
          }

          Tag
            .select_all_qualified
            .left_join(:tags, self_join, { table_alias: :tags_2 }) do
              Sequel[:tags_2][:version_order] > Sequel[:tags][:version_order]
            end
            .where(Sequel[:tags_2][:name] => nil)
            .where(Sequel[:tags][:pacticipant_id] => pacticipant_ids)
            .where(Sequel[:tags][:name] => tag_names)
        end

        # ignores tags that don't have a pact publication
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
          Tag
            .select_group(Sequel[:tags][:name], Sequel[:versions][:pacticipant_id])
            .select_append{ max(order).as(latest_consumer_version_order) }
            .join(:versions, tags_versions_join)
            .join(lp, versions_pact_publications_join)
        end

        def head_tags_for_pact_publication(pact_publication)
          Tag.where(version_id: pact_publication.consumer_version_id).all.select do | tag |
            tag_pp_join = {
              Sequel[:pact_publications][:consumer_version_id] => Sequel[:tags][:version_id],
              Sequel[:pact_publications][:consumer_id] => pact_publication.consumer_id,
              Sequel[:pact_publications][:provider_id] => pact_publication.provider_id,
              Sequel[:tags][:name] => tag.name
            }
            Tag.join(:pact_publications, tag_pp_join) do
              Sequel[:tags][:version_order] > tag.version_order
            end
            .where(pacticipant_id: pact_publication.consumer_id)
            .limit(1)
            .empty?
          end
        end
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      def before_save
        if version
          if version.order && self.version_order.nil?
            self.version_order = version.order
          end

          if self.pacticipant_id.nil?
            if version.pacticipant_id
              self.pacticipant_id = version.pacticipant_id
            elsif version&.pacticipant&.id
              self.pacticipant_id = version.pacticipant.id
            end
          end
        end

        if version_order.nil? || pacticipant_id.nil?
          raise PactBroker::Error.new("Need to set version_order and pacticipant_id for tags now")
        else
          super
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def latest_for_pacticipant?
        head_tag == self
      end

      alias_method :latest?, :latest_for_pacticipant?

      def latest_for_pact_publication?(pact_publication)
        tag_pp_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:tags][:version_id],
          Sequel[:pact_publications][:consumer_id] => pact_publication.consumer_id,
          Sequel[:pact_publications][:provider_id] => pact_publication.provider_id,
          Sequel[:tags][:name] => name
        }
        own_version_order = self.version_order
        Tag.join(:pact_publications, tag_pp_join) do
          Sequel[:tags][:version_order] > own_version_order
        end
        .where(pacticipant_id: pact_publication.consumer_id)
        .limit(1)
        .empty?
      end

      def <=> other
        name <=> other.name
      end

      def pacticipant
        version.pacticipant
      end
    end
  end
end

# Table: tags
# Primary Key: (name, version_id)
# Columns:
#  name           | text                        |
#  version_id     | integer                     |
#  created_at     | timestamp without time zone | NOT NULL
#  updated_at     | timestamp without time zone | NOT NULL
#  pacticipant_id | integer                     |
#  version_order  | integer                     |
# Indexes:
#  tags_pk                                           | PRIMARY KEY btree (version_id, name)
#  ndx_tag_name                                      | btree (name)
#  tags_pacticipant_id_index                         | btree (pacticipant_id)
#  tags_pacticipant_id_name_version_order_desc_index | btree (pacticipant_id, name, version_order DESC)
#  tags_version_id_index                             | btree (version_id)
#  tags_version_order_index                          | btree (version_order)
# Foreign key constraints:
#  tags_version_id_fkey | (version_id) REFERENCES versions(id)
