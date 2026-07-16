require "support/matrix_baseline/seed"
require "pact_broker/domain/pacticipant"
require "pact_broker/domain/verification"
require "pact_broker/pacts/pact_publication"

module MatrixBaseline
  describe Seed do
    let(:td) { TestDataBuilder.new }

    it "builds a microservice mesh large enough for non-degenerate plans" do
      result = Seed.call(td)

      expect(result[:consumers].size).to eq(Seed::CONSUMER_COUNT)
      expect(result[:providers].size).to eq(Seed::PROVIDER_COUNT)
      expect(result[:both].size).to eq(Seed::BOTH_COUNT)
      expect(result[:environment]).to eq("production")

      anchors = result[:anchors]
      expect(anchors[:consumer]).to eq("consumer-app-01")
      expect(anchors[:consumer_version]).to eq("1")
      expect(anchors[:provider]).to eq("provider-service-01")
      expect(anchors[:provider_version]).to be_a(String)
      expect(anchors[:both]).to eq("gateway-service-01")
      expect(anchors[:downstream].size).to be >= 4
      expect(anchors[:downstream]).to include("provider-service-01", "gateway-service-01")

      expect(PactBroker::Domain::Pacticipant.where(Sequel.like(:name, "consumer-app-%")).count).to eq(Seed::CONSUMER_COUNT)
      expect(PactBroker::Domain::Pacticipant.where(Sequel.like(:name, "provider-service-%")).count).to eq(Seed::PROVIDER_COUNT)
      expect(PactBroker::Domain::Pacticipant.where(Sequel.like(:name, "gateway-service-%")).count).to eq(Seed::BOTH_COUNT)

      expect(PactBroker::Pacts::PactPublication.count).to be >= Seed::CONSUMER_COUNT
      expect(PactBroker::Domain::Verification.count).to be >= Seed::CONSUMER_COUNT

      gateway = PactBroker::Domain::Pacticipant.where(name: "gateway-service-01").single_record
      expect(PactBroker::Pacts::PactPublication.where(provider_id: gateway.id).count).to be >= 1
      expect(PactBroker::Pacts::PactPublication.where(consumer_id: gateway.id).count).to be >= 1
    end
  end
end
