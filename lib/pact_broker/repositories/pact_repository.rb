require 'sequel'
require 'pact_broker/models/pacticipant'

module PactBroker
  module Repositories
    class PactRepository

      def find_by_version_and_provider version_id, provider_id
        PactBroker::Models::Pact.where(version_id: version_id, provider_id: provider_id)
      end

      def create params
        PactBroker::Models::Pact.new(version_id: params[:version_id], provider_id: params[:provider_id], json_content: params[:json_content]).save
      end

    end
  end
end