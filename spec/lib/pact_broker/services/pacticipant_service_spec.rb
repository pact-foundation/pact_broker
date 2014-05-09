require 'spec_helper'
require 'pact_broker/services/pacticipant_service'

module PactBroker

  module Services
    describe PacticipantService do

      subject{ PacticipantService }

      describe ".find_relationships" do

        let(:consumer) { instance_double("PactBroker::Models::Pacticpant")}
        let(:provider) { instance_double("PactBroker::Models::Pacticpant")}
        let(:pact) { instance_double("PactBroker::Models::Pact", consumer: consumer, provider: provider)}
        let(:pacts) { [pact]}

        before do
          allow_any_instance_of(PactBroker::Repositories::PactRepository).to receive(:find_latest_pacts).and_return(pacts)
        end

        it "returns a list of relationships" do
          expect(subject.find_relationships).to eq([PactBroker::Models::Relationship.create(consumer, provider)])
        end

      end

    end
  end
end