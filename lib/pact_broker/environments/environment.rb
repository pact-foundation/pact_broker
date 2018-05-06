require 'pact_broker/db'
require 'pact_broker/repositories/helpers'

module PactBroker

  module Environments
    class Environment < Sequel::Model

      dataset_module do
        include PactBroker::Repositories::Helpers
      end

      unrestrict_primary_key

      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      def <=> other
        name <=> other.name
      end

    end

    Environment.plugin :timestamps, update_on_create: true
  end
end
