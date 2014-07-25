require 'pact_broker/db'

module PactBroker

  module Models
    class Tag < Sequel::Model

      unrestrict_primary_key

      associate(:many_to_one, :version, :class => "PactBroker::Models::Version", :key => :version_id, :primary_key => :id)


    end

    Tag.plugin :timestamps, :update_on_create=>true
  end
end