require 'pact_broker/db'

module PactBroker

  module Models

    class Pacticipant < Sequel::Model(::DB::PACT_BROKER_DB[:pacticipants])

      one_to_many :versions

      def to_s
        "Pacticipant: id=#{id}, name=#{name}"
      end
    end
  end
end