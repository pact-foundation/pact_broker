require 'pact_broker/db'

module PactBroker

  module Domain
    class Verification < Sequel::Model

      primary_key :id
      associate(:many_to_one, :pact, class: "PactBroker::Pacts::DatabaseModel", key: :pact_id, primary_key: :id)

    end

    Verification.plugin :timestamps, update_on_create: true
  end
end