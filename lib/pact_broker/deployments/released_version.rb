require 'sequel'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Deployments
    class ReleasedVersion < Sequel::Model
      many_to_one :pacticipant, :class => "PactBroker::Domain::Pacticipant", :key => :pacticipant_id, :primary_key => :id
      many_to_one :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id
      many_to_one :environment, :class => "PactBroker::Deployments::Environment", :key => :environment_id, :primary_key => :id

      plugin :timestamps, update_on_create: true
      plugin :insert_ignore, identifying_columns: [:version_id, :environment_id]

      dataset_module do
        include PactBroker::Repositories::Helpers

        def currently_supported
          where(support_ended_at: nil)
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

        def record_support_ended
          update(support_ended_at: Sequel.datetime_class.now)
        end
      end

      def currently_supported
        support_ended_at == nil
      end
    end
  end
end
