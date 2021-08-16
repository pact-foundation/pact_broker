require "pact_broker/db"
require "pact_broker/repositories/helpers"

module PactBroker
  module Versions
    class Branch < Sequel::Model(:branches)
      plugin :timestamps, update_on_create: true
      plugin :insert_ignore, identifying_columns: [:name, :pacticipant_id]

      associate(:many_to_one, :pacticipant, :class => "PactBroker::Domain::Pacticipant", :key => :pacticipant_id, :primary_key => :id)
    end
  end
end
