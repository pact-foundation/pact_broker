require "support/matrix_baseline/seed"
require "pact_broker/domain/pacticipant"
require "pact_broker/domain/verification"
require "pact_broker/pacts/pact_publication"
require "pact_broker/deployments/environment"
require "pact_broker/deployments/deployed_version"

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

    # A seed where every pact's most recent verification passes gives the
    # success filter nothing to exclude and never lets can-i-deploy reach its
    # failure path, so those shapes would profile a filter that filters
    # nothing.
    it "leaves some pacts with a failing most-recent verification" do
      Seed.call(td)

      latest_results = PactBroker::Domain::Verification.where(number: 2).select_map(:success).uniq

      expect(latest_results).to match_array([false, true])
    end

    # The production shape the baseline exists to profile is a can-i-deploy
    # against an environment for a service with many integrations: one UNION arm
    # per integrated pacticipant. The anchor consumer has four dependencies,
    # which is not enough arms for the cost to show up.
    it "builds a wide consumer with enough environment-deployed integrations to profile the large-N shape" do
      result = Seed.call(td)

      expect(Seed::WIDE_PROVIDER_COUNT).to be >= 30
      expect(result[:wide_providers].size).to eq(Seed::WIDE_PROVIDER_COUNT)
      expect(result[:anchors][:wide_consumer]).to eq("wide-consumer-01")
      expect(result[:anchors][:wide_consumer_version]).to eq("1")

      wide_consumer = PactBroker::Domain::Pacticipant.where(name: "wide-consumer-01").single_record
      expect(PactBroker::Pacts::PactPublication.where(consumer_id: wide_consumer.id).count).to eq(Seed::WIDE_PROVIDER_COUNT)

      # Every wide provider must have a version in the environment, otherwise the
      # inferred selectors resolve to NULL_VERSION_ID and the shape profiles a
      # query that matches nothing.
      environment = PactBroker::Deployments::Environment.where(name: Seed::ENVIRONMENT).single_record
      deployed_pacticipant_ids = PactBroker::Deployments::DeployedVersion.where(environment_id: environment.id).select_map(:pacticipant_id)
      wide_provider_ids = PactBroker::Domain::Pacticipant.where(Sequel.like(:name, "wide-provider-%")).select_map(:id)

      expect(wide_provider_ids.size).to eq(Seed::WIDE_PROVIDER_COUNT)
      expect(deployed_pacticipant_ids).to include(*wide_provider_ids)
    end
  end
end
