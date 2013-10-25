require 'sequel'

module PactBroker

  module Models

    class Pacticipant < Sequel::Model(::DB::PACT_BROKER_DB[:pacticipants])

    end
  end
end