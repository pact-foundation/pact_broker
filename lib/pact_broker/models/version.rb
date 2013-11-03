require 'pact_broker/db'

module PactBroker

  module Models

    class Version < Sequel::Model(::DB::PACT_BROKER_DB[:versions])

      one_to_many :pacts

      def to_s
        "Version: number=#{number}, pacticipant=#{pacticipant_id}"
      end
    end
  end
end