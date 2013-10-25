require 'sequel'

module PactBroker

  module Models

    class Version < Sequel::Model(::DB::PACT_BROKER_DB[:versions])

    end
  end
end