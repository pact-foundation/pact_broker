require "rack/pact_broker/add_pact_broker_version_header"

module Rack
  module PactBroker
    describe AddPactBrokerVersionHeader do

      let(:app) { AddPactBrokerVersionHeader.new(->(_env){[200, {}, []]}) }

      it "adds the PactBroker version as a header" do
        get "/"
        expect(last_response.headers["x-pact-broker-version"]).to match(/\d/)
      end

    end
  end
end
