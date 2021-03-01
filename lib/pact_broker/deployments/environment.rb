require 'sequel'
require 'sequel/plugins/serialization'


module PactBroker
  module Deployments
    class Environment < Sequel::Model
      OPEN_STRUCT_TO_JSON = lambda { | open_struct | Sequel.object_to_json(open_struct.collect(&:to_h)) }
      JSON_TO_OPEN_STRUCT = lambda { | json | Sequel.parse_json(json).collect{ | hash| OpenStruct.new(hash) } }
      plugin :upsert, identifying_columns: [:uuid]
      plugin :serialization
      plugin :timestamps, update_on_create: true
      serialize_attributes [OPEN_STRUCT_TO_JSON, JSON_TO_OPEN_STRUCT], :contacts
    end
  end
end
