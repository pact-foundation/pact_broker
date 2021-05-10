require 'sequel'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Deployments
    class CurrentlyDeployedVersionId < Sequel::Model
      plugin :upsert, identifying_columns: [:pacticipant_id, :environment_id, :target_for_index]

      dataset_module do
        include PactBroker::Repositories::Helpers
      end
    end
  end
end
