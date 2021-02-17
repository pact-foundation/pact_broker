require 'pact_broker/repositories/helpers'

module PactBroker
  module Deployments
    class DeployedVersion < Sequel::Model
      many_to_one :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id
      many_to_one :environment, :class => "PactBroker::Deployments::Environment", :key => :environment_id, :primary_key => :id

      dataset_module do
        include PactBroker::Repositories::Helpers

        def currently_deployed
          where(currently_deployed: true)
        end

        def for_environment_name(environment_name)
          where(environment_id: db[:environments].select(:id).where(name: environment_name))
        end

        def for_pacticipant_name(pacticipant_name)
          where(pacticipant_id: db[:pacticipants].select(:id).where(name_like(:name, pacticipant_name)))
        end
      end
    end
  end
end
