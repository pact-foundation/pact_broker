require 'pact_broker/db'
require 'pact_broker/domain/order_versions'
require 'pact_broker/repositories/helpers'
require 'pact_broker/tags/tag_with_latest_flag'
require 'pact_broker/versions/eager_loaders'
require 'pact_broker/versions/lazy_loaders'

module PactBroker
  module Domain

    # Same attributes as PactBroker::Tags::TagWithLatestFlag
    class EagerTagWithLatestFlag < SimpleDelegator
      attr_reader :latest

      def initialize(tag, latest)
        super(tag)
        @latest = latest
      end

      def latest?
        latest
      end
    end

    class Version < Sequel::Model
      plugin :timestamps, update_on_create: true
      plugin :upsert, { identifying_columns: [:pacticipant_id, :number], ignore_columns_on_update: [:id, :created_at, :order] }

      set_primary_key :id
      one_to_many :pact_publications, order: :revision_number, class: "PactBroker::Pacts::PactPublication", key: :consumer_version_id
      associate(:many_to_one, :pacticipant, :class => "PactBroker::Domain::Pacticipant", :key => :pacticipant_id, :primary_key => :id)
      one_to_many :tags, :reciprocal => :version, order: :created_at
      one_to_many :current_deployed_versions, class: "PactBroker::Deployments::DeployedVersion", key: :version_id, primary_key: :id, order: [:created_at, :id] do | ds |
        ds.currently_deployed
      end

      one_to_many :deployed_versions, class: "PactBroker::Deployments::DeployedVersion", key: :version_id, primary_key: :id, order: [:created_at, :id]

      many_to_one :latest_version_for_pacticipant, read_only: true, key: :id,
        class: Version,
        dataset: lambda { Version.latest_version_for_pacticipant(pacticipant) },
        eager_loader: PactBroker::Versions::EagerLoaders::LatestVersionForPacticipant

      many_to_one :latest_version_for_branch, read_only: true, key: :id,
        class: Version,
        dataset: PactBroker::Versions::LazyLoaders::LATEST_VERSION_FOR_BRANCH,
        eager_loader: PactBroker::Versions::EagerLoaders::LatestVersionForBranch

      dataset_module do
        include PactBroker::Repositories::Helpers

        def latest_version_for_pacticipant(pacticipant)
          where(pacticipant: pacticipant)
          .order(Sequel.desc(:order))
          .limit(1)
        end

        def for(pacticipant_name, version_number)
          where_pacticipant_name(pacticipant_name).where_number(version_number).single_record
        end

        def latest_versions_for_pacticipant_branches(pacticipant_id, branches)
          query = Version.where(Sequel[:versions][:pacticipant_id] => pacticipant_id, Sequel[:versions][:branch] => branches)

          self_join = {
            Sequel[:versions][:pacticipant_id] => Sequel[:versions_2][:pacticipant_id],
            Sequel[:versions][:branch] => Sequel[:versions_2][:branch]
          }
          query.select_all_qualified.left_join(query, self_join, table_alias: :versions_2) do
            Sequel[:versions_2][:order] > Sequel[:versions][:order]
          end
          .where(Sequel[:versions_2][:order] => nil)
        end

        def where_pacticipant_name(pacticipant_name)
          where(Sequel[:versions][:pacticipant_id] => db[:pacticipants].select(:id).where(name_like(:name, pacticipant_name)))
          # If we do a join, we get the extra columns from the pacticipant table that then
          # make == not work
          # join(:pacticipants) do | p |
          #   Sequel.&(
          #     { Sequel[first_source_alias][:pacticipant_id] => Sequel[p][:id] },
          #     name_like(Sequel[p][:name], pacticipant_name)
          #   )
          # end
        end

        def currently_deployed_to_environment(environment_name, pacticipant_name)
          deployed_version_query = PactBroker::Deployments::DeployedVersion.currently_deployed.for_environment_name(environment_name)
          deployed_version_query = deployed_version_query.for_pacticipant_name(pacticipant_name) if pacticipant_name
          where(id: deployed_version_query.select(:version_id))
        end

        def where_tag(tag)
          if tag == true
            join(:tags, Sequel[:tags][:version_id] => Sequel[first_source_alias][:id])
          else
            join(:tags) do | tags |
              Sequel.&(
                { Sequel[first_source_alias][:id] => Sequel[tags][:version_id] },
                name_like(Sequel[tags][:name], tag)
              )
            end
          end
        end

        def where_branch(branch)
          where(branch: branch)
        end

        def where_number(number)
          where(name_like(:number, number))
        end

        def where_age_less_than(days)
          start_date = Date.today - days
          where{ versions[:created_at] >= start_date }
        end

        def delete
          require 'pact_broker/pacts/pact_publication'
          require 'pact_broker/domain/verification'
          require 'pact_broker/domain/tag'
          require 'pact_broker/deployments/deployed_version'

          PactBroker::Deployments::DeployedVersion.where(version: self).delete
          PactBroker::Domain::Verification.where(provider_version: self).delete
          PactBroker::Pacts::PactPublication.where(consumer_version: self).delete
          PactBroker::Domain::Tag.where(version: self).delete
          super
        end

        def for_selector(selector)
          query = self
          query = query.where_pacticipant_name(selector.pacticipant_name) if selector.pacticipant_name
          query = query.currently_deployed_to_environment(selector.environment_name, selector.pacticipant_name) if selector.environment_name
          query = query.where_tag(selector.tag) if selector.tag
          query = query.where_branch(selector.branch) if selector.branch
          query = query.where_number(selector.pacticipant_version_number) if selector.pacticipant_version_number
          query = query.where_age_less_than(selector.max_age) if selector.max_age

          if selector.latest
            calculate_max_version_order_and_join_back_to_versions(query, selector)
          else
            query
          end
        end

        # private

        def calculate_max_version_order_and_join_back_to_versions(query, selector)
          versions_join = {
            Sequel[:versions][:pacticipant_id] => Sequel[:latest][:pacticipant_id],
            Sequel[:versions][:order]          => Sequel[:latest][:latest_version_order]
          }

          group_by_cols = selector.tag == true ? [Sequel[:versions][:pacticipant_id], Sequel[:tags][:name]] : [Sequel[:versions][:pacticipant_id]]

          max_order_for_each_pacticipant = query
              .select_group(*group_by_cols)
              .select_append{ max(order).as(latest_version_order) }

          join(max_order_for_each_pacticipant, versions_join, table_alias: :latest)
        end
      end

      # Isn't called on upsert when the record is updated with Sqlite
      # Is called with Postgres/MySQL
      # Haven't had time to dig into why
      def after_create
        super
        OrderVersions.(self) unless self.order
        refresh
      end

      def before_destroy
        PactBroker::Deployments::DeployedVersion.where(version: self).destroy
        PactBroker::Domain::Tag.where(version: self).destroy
        super
      end

      def to_s
        "Version: number=#{number}, pacticipant=#{pacticipant_id}"
      end

      def version_and_updated_date
        "Version #{number} - #{updated_at.to_time.localtime.strftime("%d/%m/%Y")}"
      end

      def head_tags
        tags.select(&:latest_for_pacticipant?)
      end

      # What about provider??? This makes no sense
      def latest_pact_publication
        pact_publications.last
      end

      def latest_for_branch?
        branch ? latest_version_for_branch.order == order : nil
      end

      def latest_for_pacticipant?
        latest_version_for_pacticipant == self
      end
    end
  end
end

# Table: versions
# Columns:
#  id             | integer                     | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  number         | text                        |
#  repository_ref | text                        |
#  pacticipant_id | integer                     | NOT NULL
#  order          | integer                     |
#  created_at     | timestamp without time zone | NOT NULL
#  updated_at     | timestamp without time zone | NOT NULL
#  branch         | text                        |
#  build_url      | text                        |
# Indexes:
#  versions_pkey                              | PRIMARY KEY btree (id)
#  uq_ver_ppt_ord                             | UNIQUE btree (pacticipant_id, "order")
#  versions_pacticipant_id_number_index       | UNIQUE btree (pacticipant_id, number)
#  ndx_ver_num                                | btree (number)
#  ndx_ver_ord                                | btree ("order")
#  versions_pacticipant_id_branch_order_index | btree (pacticipant_id, branch, "order")
#  versions_pacticipant_id_order_desc_index   | btree (pacticipant_id, "order" DESC)
# Foreign key constraints:
#  versions_pacticipant_id_fkey | (pacticipant_id) REFERENCES pacticipants(id)
# Referenced By:
#  tags                                                         | tags_version_id_fkey                                            | (version_id) REFERENCES versions(id)
#  pact_publications                                            | pact_publications_consumer_version_id_fkey                      | (consumer_version_id) REFERENCES versions(id)
#  verifications                                                | fk_verifications_versions                                       | (provider_version_id) REFERENCES versions(id)
#  latest_pact_publication_ids_for_consumer_versions            | latest_pact_publication_ids_for_consum_consumer_version_id_fkey | (consumer_version_id) REFERENCES versions(id) ON DELETE CASCADE
#  latest_verification_id_for_pact_version_and_provider_version | latest_v_id_for_pv_and_pv_provider_version_id_fk                | (provider_version_id) REFERENCES versions(id) ON DELETE CASCADE
