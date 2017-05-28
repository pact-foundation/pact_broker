require 'pact_broker/db'

module PactBroker

  module Domain
    class Tag < Sequel::Model

      unrestrict_primary_key

      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      def <=> other
        name <=> other.name
      end

    end

    Tag.plugin :timestamps, :update_on_create=>true
  end
end