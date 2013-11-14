require 'spec_helper'

require 'pact_broker/models'
require 'pact_broker/api/decorators'

module PactBroker::Api::Decorators

  describe PactCollectionRepresenter do

    let(:pact) do
      provider = PactBroker::Models::Pacticipant.create(:name => 'Pricing Service')
      consumer = PactBroker::Models::Pacticipant.create(:name => 'Condor')
      version = PactBroker::Models::Version.create(:number => '1.3.0', :pacticipant => consumer)
      pact = PactBroker::Models::Pact.create(:consumer_version => version, :provider => provider)
      pact
    end

    xit "should description" do
      puts PactCollectionRepresenter.new([pact]).to_json
    end
  end

end