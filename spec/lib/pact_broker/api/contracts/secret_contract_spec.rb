require 'pact_broker/api/contracts/secret_contract'
require 'pact_broker/project_root'

module PactBroker
  module Api
    module Contracts
      describe 'SecretContract' do
        let(:params) { {} }
        let(:secret_contract) { SecretContract.new }
        let(:errors) { secret_contract.validate(params); secret_contract.errors }

        context "with empty params" do
          it "has errors" do
            expect(errors).to eq ({ name: ["name is missing"], value: ["value is missing"] })
          end
        end

        context "when required params are present but blank" do
          let(:params) do
            {
              name: " ",
              value: ""
            }
          end

          it "has an error for the name but not the value" do
            expect(errors[:name]).to eq ["name can't be blank"]
            expect(errors).to_not have_key(:value)
          end
        end
      end
    end
  end
end
