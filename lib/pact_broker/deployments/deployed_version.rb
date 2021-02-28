require 'pact_broker/repositories/helpers'

module PactBroker
  module Deployments
    class DeployedVersion < Sequel::Model
      many_to_one :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id
      many_to_one :environment, :class => "PactBroker::Deployments::Environment", :key => :environment_id, :primary_key => :id

      plugin :timestamps, update_on_create: true

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
          where(currently_deployed: true)
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
      end

      def record_undeployed
        update(currently_deployed: false, undeployed_at: Sequel.datetime_class.now)
      end
    end
  end
end
