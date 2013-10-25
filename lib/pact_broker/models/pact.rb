require 'sequel'

module PactBroker

  module Models
    class Pact < Sequel::Model(::DB::PACT_BROKER_DB[:pacts])

    end
  end
end
