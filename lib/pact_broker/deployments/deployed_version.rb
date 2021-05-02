require 'pact_broker/repositories/helpers'
require 'pact_broker/deployments/currently_deployed_version_id'

module PactBroker
  module Deployments
    DEPLOYED_VERSION_COLUMNS = [:id, :uuid, :version_id, :pacticipant_id, :environment_id, :target, :created_at, :updated_at, :undeployed_at]
    DEPLOYED_VERSION_DATASET = Sequel::Model.db[:deployed_versions].select(*DEPLOYED_VERSION_COLUMNS)
    class DeployedVersion < Sequel::Model(DEPLOYED_VERSION_DATASET)
      many_to_one :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id
      many_to_one :environment, :class => "PactBroker::Deployments::Environment", :key => :environment_id, :primary_key => :id
      one_to_one :currently_deployed_version_id, :class => "PactBroker::Deployments::CurrentlyDeployedVersionId", key: :deployed_version_id, primary_key: :id

      plugin :timestamps, update_on_create: true
      plugin :insert_ignore, identifying_columns: [:pacticipant_id, :version_id, :environment_id, :target]


      dataset_module do
        include PactBroker::Repositories::Helpers

        def last_deployed_version(pacticipant, environment)
          currently_deployed
            .where(pacticipant_id: pacticipant.id)
            .where(environment: environment)
            .order(Sequel.desc(:created_at), Sequel.desc(:id))
            .first
        end

        def currently_deployed
          where(id: CurrentlyDeployedVersionId.select(:deployed_version_id))
        end

        def undeployed
          exclude(undeployed_at: nil)
        end

        def for_version_and_environment_and_target(version, environment, target)
          for_version_and_environment(version, environment).for_target(target)
        end

        def for_target(target)
          where(target: target)
        end

        def for_environment_name(environment_name)
          where(environment_id: db[:environments].select(:id).where(name: environment_name))
        end

        def for_pacticipant_name(pacticipant_name)
          where(pacticipant_id: db[:pacticipants].select(:id).where(name_like(:name, pacticipant_name)))
        end

        def for_version_and_environment(version, environment)
          where(version_id: version.id, environment_id: environment.id)
        end

        def for_environment(environment)
          where(environment_id: environment.id)
        end

        def order_by_date_desc
          order(Sequel.desc(:created_at), Sequel.desc(:id))
        end

        def record_undeployed
          update(undeployed_at: Sequel.datetime_class.now)
        end
      end

      def after_create
        super
        CurrentlyDeployedVersionId.new(
          pacticipant_id: pacticipant_id,
          environment_id: environment_id,
          version_id: version_id,
          target: target,
          deployment_complete: deployment_complete,
          deployed_version_id: id
        ).upsert
      end

      def currently_deployed
        !!currently_deployed_version_id
      end

      def version_number
        version.number
      end
    end
  end
end
