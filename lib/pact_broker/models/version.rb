require 'sequel'

module PactBroker

  module Models

    class Version < Sequel::Model(::DB::PACT_BROKER_DB[:versions])
      def to_s
        "Version: number=#{number}, pacticipant=#{pacticipant_id}"
      end
    end
  end
end