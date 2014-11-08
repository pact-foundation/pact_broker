require 'pact_broker/domain/pact'

module PactBroker
  module Pacts

    class DatabaseModel < Sequel::Model(:pacts)

      set_primary_key :id
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer_version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      DatabaseModel.plugin :timestamps, :update_on_create=>true

      def to_domain
        PactBroker::Domain::Pact.new(
          id: id,
          provider: provider,
          consumer: consumer_version.pacticipant,
          consumer_version_number: consumer_version.number,
          consumer_version: consumer_version,
          json_content: json_content,
          updated_at: updated_at,
          created_at: created_at
          )
      end
    end

  end
end