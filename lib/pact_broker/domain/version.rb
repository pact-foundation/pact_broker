require "pact_broker/dataset"
require "pact_broker/domain/order_versions"
require "pact_broker/tags/tag_with_latest_flag"
require "pact_broker/versions/eager_loaders"

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

    VERSION_COLUMNS = [:id, :number, :repository_ref, :pacticipant_id, :order, :created_at, :updated_at, :build_url]

    class Version < Sequel::Model(Sequel::Model.db[:versions].select(*VERSION_COLUMNS.collect{ | column | Sequel.qualify(:versions, column) }))
      set_primary_key :id

      plugin :timestamps, update_on_create: true
      plugin :age
      plugin :upsert, { identifying_columns: [:pacticipant_id, :number], ignore_columns_on_update: [:id, :created_at, :order] }

      one_to_many :pact_publications, order: :revision_number, class: "PactBroker::Pacts::PactPublication", key: :consumer_version_id
      associate(:many_to_one, :pacticipant, :class => "PactBroker::Domain::Pacticipant", :key => :pacticipant_id, :primary_key => :id)
      one_to_many :tags, :reciprocal => :version, order: :created_at
      one_to_many :branch_versions, :reciprocal => :branch_version, class: "PactBroker::Versions::BranchVersion", order: [:created_at, :id]
      one_to_many :branch_heads, reciprocal: :branch_head, class: "PactBroker::Versions::BranchHead", order: :branch_id
      one_to_many :current_deployed_versions, class: "PactBroker::Deployments::DeployedVersion", key: :version_id, primary_key: :id, order: [:created_at, :id] do | ds |
        ds.currently_deployed
      end
      one_to_many :current_supported_released_versions, class: "PactBroker::Deployments::ReleasedVersion", key: :version_id, primary_key: :id, order: [:created_at, :id] do | ds |
        ds.currently_supported
      end

      one_to_many :deployed_versions, class: "PactBroker::Deployments::DeployedVersion", key: :version_id, primary_key: :id, order: [:created_at, :id]
      one_to_many :released_versions, class: "PactBroker::Deployments::ReleasedVersion", key: :version_id, primary_key: :id, order: [:created_at, :id]

      many_to_one :latest_version_for_pacticipant, read_only: true, key: :id,
        class: Version,
        dataset: lambda { Version.latest_version_for_pacticipant(pacticipant) },
        eager_loader: PactBroker::Versions::EagerLoaders::LatestVersionForPacticipant

      dataset_module do
        include PactBroker::Dataset

        def with_branch
          where(id: PactBroker::Versions::BranchVersion.select(:version_id))
        end

        def with_user_created_branch
          where(id: PactBroker::Versions::BranchVersion.select(:version_id).where(auto_created: false))
        end

        def latest_version_for_pacticipant(pacticipant)
          where(pacticipant: pacticipant)
          .order(Sequel.desc(:order))
          .limit(1)
        end

        def for(pacticipant_name, version_number)
          where_pacticipant_name(pacticipant_name).where_number(version_number).single_record
        end

        def where_pacticipant_name_and_version_number(pacticipant_name, version_number)
          where_pacticipant_name(pacticipant_name).where_number(version_number)
        end

        def first_for_pacticipant_id_and_branch(pacticipant_id, branch)
          first_version_id = PactBroker::Versions::BranchVersion
                              .select(:version_id)
                              .where(pacticipant_id: pacticipant_id, branch_name: branch)
                              .order(:created_at)
                              .limit(1)
          where(id: first_version_id).single_record
        end

        def latest_versions_for_pacticipant_branches(pacticipant_id, branch_names)
          where(id: PactBroker::Versions::BranchHead.where(pacticipant_id: pacticipant_id, branch_name: branch_names).select(:version_id))
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

        def currently_in_environment(environment_name, pacticipant_name)
          currently_deployed_to_environment(environment_name, pacticipant_name).union(currently_supported_in_environment(environment_name, pacticipant_name))
        end

        def currently_deployed_to_environment(environment_name, pacticipant_name)
          deployed_version_query = PactBroker::Deployments::DeployedVersion.currently_deployed.for_environment_name(environment_name)
          deployed_version_query = deployed_version_query.for_pacticipant_name(pacticipant_name) if pacticipant_name
          where(id: deployed_version_query.select(:version_id))
        end

        def currently_supported_in_environment(environment_name, pacticipant_name)
          supported_version_query = PactBroker::Deployments::ReleasedVersion.currently_supported.for_environment_name(environment_name)
          supported_version_query = supported_version_query.for_pacticipant_name(pacticipant_name) if pacticipant_name
          where(id: supported_version_query.select(:version_id))
        end

        def currently_deployed
          deployed_version_query = PactBroker::Deployments::DeployedVersion.currently_deployed
          where(id: deployed_version_query.select(:version_id))
        end

        def currently_supported
          supported_version_query = PactBroker::Deployments::ReleasedVersion.currently_supported
          where(id: supported_version_query.select(:version_id))
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

        def where_branch_name(branch_name)
          if branch_name == true
            where(id: PactBroker::Versions::BranchVersion.select(:version_id))
          else
            matching_branch_ids = PactBroker::Versions::Branch.select(:id).where(name: branch_name)
            branch_version_ids = PactBroker::Versions::BranchVersion
                                            .select(:version_id, :branch_name)
                                            .where(branch_id: matching_branch_ids)
            select_append(:branch_name)
              .join(branch_version_ids, { Sequel[first_source_alias][:id] => Sequel[:bv][:version_id] }, { table_alias: :bv})

          end
        end

        def where_branch_head_name(branch_name)
          if branch_name == true
            where(id: PactBroker::Versions::BranchHead.select(:version_id))
          else
            branch_heads = PactBroker::Versions::BranchHead.select(:version_id, :branch_name).where(branch_name: branch_name)
            select_append(:branch_name)
              .join(branch_heads, { Sequel[first_source_alias][:id] => Sequel[:bh][:version_id] }, { table_alias: :bh })
          end
        end


        def for_main_branches
          branch_version_ids = PactBroker::Versions::BranchVersion
                                          .select(:version_id, :branch_name)
                                          .join(:pacticipants, { Sequel[:branch_versions][:pacticipant_id] => Sequel[:pacticipants][:id] })
                                          .join(:branches, { Sequel[:branches][:id] => Sequel[:branch_versions][:branch_id], Sequel[:branches][:name] => Sequel[:pacticipants][:main_branch] })

          select_append(Sequel[:bv][:branch_name])
            .join(branch_version_ids, { Sequel[first_source_alias][:id] => Sequel[:bv][:version_id]  }, table_alias: :bv)

        end

        def latest_for_main_branches
          pacticipants_join = {
            Sequel[:branch_heads][:pacticipant_id] => Sequel[:pacticipants][:id],
            Sequel[:branch_heads][:branch_name] => Sequel[:pacticipants][:main_branch]
          }
          branch_head_version_ids = PactBroker::Versions::BranchHead
                                          .select(:version_id, :branch_name)
                                          .join(:pacticipants, pacticipants_join)

          select_append(Sequel[:bh][:branch_name])
            .join(branch_head_version_ids, { Sequel[first_source_alias][:id] => Sequel[:bh][:version_id]  }, table_alias: :bh)

        end

        def where_number(number)
          where(name_like(:number, number))
        end

        def where_age_less_than(days)
          start_date = Date.today - days
          where{ versions[:created_at] >= start_date }
        end

        def delete
          require "pact_broker/pacts/pact_publication"
          require "pact_broker/domain/verification"
          require "pact_broker/domain/tag"
          require "pact_broker/deployments/deployed_version"
          require "pact_broker/deployments/released_version"

          PactBroker::Deployments::DeployedVersion.where(version: self).delete
          PactBroker::Deployments::ReleasedVersion.where(version: self).delete
          PactBroker::Domain::Verification.where(provider_version: self).delete
          PactBroker::Pacts::PactPublication.where(consumer_version: self).delete
          PactBroker::Domain::Tag.where(version: self).delete
          super
        end

        # rubocop: disable Metrics/CyclomaticComplexity
        def for_selector(selector)
          query = self
          query = query.where_pacticipant_name(selector.pacticipant_name) if selector.pacticipant_name
          query = query.currently_in_environment(selector.environment_name, selector.pacticipant_name) if selector.environment_name
          query = query.currently_deployed if selector.respond_to?(:currently_deployed?) && selector.currently_deployed?
          query = query.currently_supported if selector.respond_to?(:currently_supported?) && selector.currently_supported?
          query = query.where_tag(selector.tag) if selector.tag
          query = query.where_number(selector.pacticipant_version_number) if selector.respond_to?(:pacticipant_version_number) && selector.pacticipant_version_number
          query = query.where_age_less_than(selector.max_age) if selector.respond_to?(:max_age) && selector.max_age

          latest_applied = false

          if selector.respond_to?(:main_branch) && selector.main_branch
            if selector.latest
              latest_applied = true
              query = query.latest_for_main_branches
            else
              query = query.for_main_branches
            end
          end

          if selector.branch
            if selector.latest
              latest_applied = true
              query = query.where_branch_head_name(selector.branch)
            else
              query = query.where_branch_name(selector.branch)
            end
          end

          if selector.latest && !latest_applied
            calculate_max_version_order_and_join_back_to_versions(query, selector)
          else
            query
          end
        end
        # rubocop: enable Metrics/CyclomaticComplexity

        def pacticipants_set
          from_self(alias: :v)
            .select_group(Sequel[:v][:pacticipant_id])
            .collect(&:pacticipant_id)
            .to_set
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
        PactBroker::Deployments::ReleasedVersion.where(version: self).destroy
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
        branch_heads.any?
      end

      def latest_for_pacticipant?
        latest_version_for_pacticipant == self
      end

      def branch_version_for_branch(branch)
        branch_versions.find { | branch_version | branch_version.branch_id == branch.id }
      end

      def branch_version_for_branch_name(branch_name)
        branch_versions.find { | branch_version | branch_version.branch_name == branch_name }
      end

      def branch_names
        branch_versions.collect(&:branch_name)
      end

      def tag_names
        tags.collect(&:name)
      end

      def branch
        raise NotImplementedError
      end

      def branch= branch
        raise NotImplementedError
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
#  branch_versions                                              | branch_versions_versions_fk                                     | (version_id) REFERENCES versions(id) ON DELETE CASCADE
#  currently_deployed_version_ids                               | currently_deployed_version_ids_version_id_fkey                  | (version_id) REFERENCES versions(id) ON DELETE CASCADE
#  deployed_versions                                            | deployed_versions_version_id_fkey                               | (version_id) REFERENCES versions(id)
#  latest_pact_publication_ids_for_consumer_versions            | latest_pact_publication_ids_for_consum_consumer_version_id_fkey | (consumer_version_id) REFERENCES versions(id) ON DELETE CASCADE
#  latest_verification_id_for_pact_version_and_provider_version | latest_v_id_for_pv_and_pv_provider_version_id_fk                | (provider_version_id) REFERENCES versions(id) ON DELETE CASCADE
#  pact_publications                                            | pact_publications_consumer_version_id_fkey                      | (consumer_version_id) REFERENCES versions(id)
#  released_versions                                            | released_versions_version_id_fkey                               | (version_id) REFERENCES versions(id)
#  tags                                                         | tags_version_id_fkey                                            | (version_id) REFERENCES versions(id)
#  verifications                                                | fk_verifications_versions                                       | (provider_version_id) REFERENCES versions(id)
