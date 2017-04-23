require 'pact_broker/db'

module PactBroker

  module Domain
    class Verification < Sequel::Model

      set_primary_key :id
      associate(:many_to_one, :pact_publication, class: "PactBroker::Pacts::PactPublication", key: :pact_publication_id, primary_key: :id)

    end

    Verification.plugin :timestamps, update_on_create: true
  end
end