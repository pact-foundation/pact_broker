require 'pact_broker/verifications/repository'

module PactBroker
  module Verifications
    describe Repository do

      describe "#verification_count_for_pact" do
        let!(:pact_1) do
          TestDataBuilder.new
            .create_consumer("Consumer")
            .create_provider("Provider")
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1)
            .create_verification(number: 2)
            .and_return(:pact)
        end
        let!(:pact_2) do
          TestDataBuilder.new
            .create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("4.5.6")
            .create_pact
            .create_verification(number: 1)
            .and_return(:pact)
        end

        it "returns the number of verifications for the given pact" do
          expect(Repository.new.verification_count_for_pact(pact_1)).to eq 2
        end
      end

      describe "#find" do
        let!(:pact) do
          builder = TestDataBuilder.new
          pact = builder
            .create_provider("Provider1")
            .create_consumer("Consumer1")
            .create_consumer_version("1.0.0")
            .create_pact
            .and_return(:pact)

          builder
            .create_verification(number: 1)
            .create_verification(number: 2, provider_version: '3.7.4')
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1)

            TestDataBuilder.new
            .create_provider("Provider3")
            .create_consumer("Consumer2")
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1)
          pact
        end

        let(:verification) { Repository.new.find "Consumer1", "Provider1", pact.pact_version_sha, 2}

        it "finds the latest verifications for the given consumer version" do
          expect(verification.provider_version).to eq "3.7.4"
          expect(verification.consumer_name).to eq "Consumer1"
          expect(verification.provider_name).to eq "Provider1"
          expect(verification.pact_version_sha).to eq pact.pact_version_sha
        end
      end

      describe "#find_latest_verifications_for_consumer_version" do
        before do
          TestDataBuilder.new
            .create_provider("Provider1")
            .create_consumer("Consumer1")
            .create_consumer_version("1.0.0")
            .create_pact
            .create_verification(number: 1)
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1)
            .create_verification(number: 2, provider_version: "7.8.9")
            .create_provider("Provider2")
            .create_pact
            .create_verification(number: 1, provider_version: "6.5.4")

            TestDataBuilder.new
            .create_provider("Provider3")
            .create_consumer("Consumer2")
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1)
        end

        let(:latest_verifications) { Repository.new.find_latest_verifications_for_consumer_version("Consumer1", "1.2.3")}

        it "finds the latest verifications for the given consumer version" do
          expect(latest_verifications.first.provider_version).to eq "7.8.9"
          expect(latest_verifications.last.provider_version).to eq "6.5.4"
        end
      end

      describe "#find_latest_verification_for" do
        before do
          TestDataBuilder.new
            .create_provider("Provider1")
            .create_consumer("Consumer1")
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1, provider_version: "2.3.4")
            .create_verification(number: 2, provider_version: "7.8.9")
            .create_consumer_version("1.0.0")
            .create_pact
            .create_verification(number: 1, provider_version: "5.4.3")
            .create_provider("Provider2")
            .create_pact
            .create_verification(number: 1, provider_version: "6.5.4")
            .create_consumer_version("2.0.0")
            .create_pact
        end

        let(:latest_verification) { Repository.new.find_latest_verification_for("Consumer1", "Provider1")}

        it "finds the latest verifications for the given consumer version" do
          expect(latest_verification.provider_version).to eq "7.8.9"
        end
      end
    end
  end
end
