require 'pact_broker/db'

module PactBroker
  module Integrations
    class Integration < Sequel::Model
      associate(:many_to_one, :consumer, :class => "PactBroker::Domain::Pacticipant", :key => :consumer_id, :primary_key => :id)
      associate(:many_to_one, :provider, :class => "PactBroker::Domain::Pacticipant", :key => :provider_id, :primary_key => :id)
    end
  end
end

# Table: integrations
# Columns:
#  consumer_id   | integer |
#  consumer_name | text    |
#  provider_id   | integer |
#  provider_name | text    |
