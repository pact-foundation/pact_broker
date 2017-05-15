require 'pact_broker/app'

module PactBroker
  describe App do

    let(:app) do
      PactBroker::App.new do | configuration |
        configuration.database_connection = PactBroker::DB.connection
      end
    end

    it "adds the X-Pact-Broker-Version header" do
      get "/"
      expect(last_response.headers['X-Pact-Broker-Version']).to match /\d/
    end

  end
end
