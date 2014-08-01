require 'spec_helper'
require 'pact_broker/api/resources/pact'
require 'rack/test'

module PactBroker::Api

  module Resources

    describe Pact do

      include Rack::Test::Methods

      let(:app) { PactBroker::API }

      describe "PUT" do

        context "with invalid JSON" do

          before do
            put ""
          end

          it "returns a 400 response"

          it "returns a JSON body"

          it "returns an error message"
        end
      end

    end
  end

end
