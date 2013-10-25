require 'sequel'

module PactBroker

  module Models

    class Pacticipant < Sequel::Model(::DB::PACT_BROKER_DB[:pacticipants])
      def to_s
        "Pacticipant: id=#{id}, name=#{name}"
      end
    end
  end
end