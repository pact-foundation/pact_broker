module PactBroker
  module Secrets
    class UnencryptedSecret
      attr_accessor :uuid, :name, :description, :value, :created_at, :updated_at

      def initialize(params = {})
        @uuid = params[:uuid]
        @name = params[:name]
        @description = params[:description]
        @value = params[:value]
        @created_at = params[:created_at]
        @updated_at = params[:updated_at]
      end
    end
  end
end
