module PactBroker
  module Contracts
    ContractToPublish = Struct.new(:provider_name, :content, :content_type, :contract_specification, :role) do
      def self.from_hash(params)
        new(params[:provider_name],
          params[:content],
          params[:content_type],
          params[:contract_specification],
          params[:role]
        )
      end
    end
  end
end
