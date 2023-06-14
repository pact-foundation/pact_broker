
require "pact_broker/domain"
require "pact_broker/api/decorators"

module PactBroker::Api::Decorators

  describe PactCollectionDecorator do

    let(:pact) do
      provider = PactBroker::Domain::Pacticipant.create(:name => "Pricing Service")
      consumer = PactBroker::Domain::Pacticipant.create(:name => "Condor")
      version = PactBroker::Domain::Version.create(:number => "1.3.0", :pacticipant => consumer)
      pact = PactBroker::Domain::Pact.create(:consumer_version => version, :provider => provider)
      pact
    end

    xit "should description" do
      puts PactCollectionDecorator.new([pact]).to_json
    end
  end

end