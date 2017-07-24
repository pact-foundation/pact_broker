require 'pact_broker/db'

module PactBroker
  module Domain
    class Label < Sequel::Model

      unrestrict_primary_key

      associate(:many_to_one, :pacticipant, :class => "PactBroker::Domain::Pacticipant", :key => :pacticipant_id, :primary_key => :id)

      def <=> other
        name <=> other.name
      end

    end

    Label.plugin :timestamps, update_on_create: true
  end
end
