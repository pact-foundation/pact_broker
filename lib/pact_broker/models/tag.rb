require 'sequel'

module PactBroker

  module Models
    class Tag < Sequel::Model

      unrestrict_primary_key

      associate(:many_to_one, :version, :class => "PactBroker::Models::Version", :key => :version_id, :primary_key => :id)


    end
  end
end