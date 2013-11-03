require 'pact_broker/db'

module PactBroker

  module Models
    class Pact < Sequel::Model(::DB::PACT_BROKER_DB[:pacts])
      def to_s
        "Pact: provider_id=#{provider_id}"
      end
    end
  end
end
