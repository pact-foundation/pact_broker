require 'pact_broker/domain/tag'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/domain/version'

module PactBroker
  module Pacts

    class AllPacts < Sequel::Model(:all_pacts)

      associate(:one_to_many, :tags, :class => "PactBroker::Domain::Tag", :reciprocal => :version, :key => :version_id, :primary_key => :consumer_version_id)

      def to_domain
        consumer = Domain::Pacticipant.new(name: consumer_name)
        consumer.id = consumer_id
        provider = Domain::Pacticipant.new(name: provider_name)
        provider.id = provider_id
        consumer_version = OpenStruct.new(
          number: consumer_version_number,
          order: consumer_version_order,
          pacticipant: consumer,
          tags: tags)
        Domain::Pact.new(id: id,
          consumer: consumer,
          consumer_version: consumer_version,
          provider: provider,
          consumer_version_number: consumer_version_number,
          json_content: json_content,
          created_at: created_at,
          updated_at: updated_at)
      end

    end

  end
end
