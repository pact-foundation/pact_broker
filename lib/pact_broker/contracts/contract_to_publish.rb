module PactBroker
  module Contracts
    ContractToPublish = Struct.new(:consumer_name, :provider_name, :decoded_content, :content_type, :specification) do
      def self.from_hash(params)
        new(params[:consumer_name],
          params[:provider_name],
          params[:decoded_content],
          params[:content_type],
          params[:specification]
        )
      end
    end
  end
end
