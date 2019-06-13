module PactBroker
  module Secrets
    class UnencryptedSecret
      attr_accessor :uuid, :name, :description, :value, :created_at, :updated_at

      def initialize(uuid: nil, name: nil, description: nil, value: nil, created_at: nil, updated_at: nil)
        @uuid = uuid
        @name = name
        @description = description
        @value = value
        @created_at = created_at
        @updated_at = updated_at
      end
    end
  end
end
