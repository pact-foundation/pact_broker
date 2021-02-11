require 'sequel'

module PactBroker
  module Deployments
    class Environment < Sequel::Model
      plugin :upsert, identifying_columns: [:uuid]
      plugin :serialization, :json, :contacts
    end
  end
end
