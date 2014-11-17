require 'sequel'

module PactBroker
  module Pacts
    class PactVersionContent < Sequel::Model(:pact_version_contents)
      set_primary_key :id
    end

    PactVersionContent.plugin :timestamps, :update_on_create=>true
  end
end
