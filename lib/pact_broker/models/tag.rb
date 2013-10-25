require 'sequel'

module PactBroker

  module Models
    class Tag < Sequel::Model(::DB::PACT_BROKER_DB[:tags])

    end
  end
end