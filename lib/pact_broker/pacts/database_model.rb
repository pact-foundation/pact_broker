require 'pact_broker/domain/pact'
require 'pact_broker/pacts/pact_version_content'

module PactBroker
  module Pacts

    class DatabaseModel < Sequel::Model(:pacts)

      set_primary_key :id
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer_version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)
      associate(:many_to_one, :pact_version_content, :key => :pact_version_content_id, :primary_key => :id)

      DatabaseModel.plugin :timestamps, :update_on_create=>true

      def to_domain
        PactBroker::Domain::Pact.new(
          id: id,
          provider: provider,
          consumer: consumer_version.pacticipant,
          consumer_version_number: consumer_version.number,
          consumer_version: to_version_domain,
          json_content: pact_version_content.content,
          updated_at: updated_at,
          created_at: created_at
          )
      end

      def to_version_domain
        OpenStruct.new(number: consumer_version.number, pacticipant: consumer_version.pacticipant, tags: consumer_version.tags, order: consumer_version.order)
      end

    end
  end
end