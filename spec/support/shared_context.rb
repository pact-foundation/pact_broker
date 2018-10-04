RSpec.shared_context "stubbed services" do

  let(:pact_service) { class_double("PactBroker::Pacts::Service").as_stubbed_const }
  let(:pacticipant_service) { class_double("PactBroker::Pacticipants::Service").as_stubbed_const }

  before do
    allow_any_instance_of(described_class).to receive(:pact_service).and_return(pact_service)
    allow_any_instance_of(described_class).to receive(:pacticipant_service).and_return(pacticipant_service)
  end
end
