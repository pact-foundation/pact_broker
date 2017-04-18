require 'pact_broker/db'

module PactBroker

  module Domain
    class Verification < Sequel::Model

      set_primary_key :id
      associate(:many_to_one, :pact_revision, class: "PactBroker::Pacts::PactRevision", key: :pact_revision_id, primary_key: :id)

    end

    Verification.plugin :timestamps, update_on_create: true
  end
end