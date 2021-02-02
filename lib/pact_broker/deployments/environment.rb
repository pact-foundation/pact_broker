require 'sequel'

module PactBroker
  module Deployments
    class Environment < Sequel::Model
      plugin :upsert, identifying_columns: [:name]
      plugin :serialization, :json, :owners
    end
  end
end
