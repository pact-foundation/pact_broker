require 'pact_broker/matrix/repository'

module PactBroker
  module Matrix
    describe Repository do
      describe "#find" do
        before do
          TestDataBuilder.new
            .create_pact_with_hierarchy("Consumer", "1.2.3", "Provider")
            .create_verification(provider_version: "6.7.8")
            .revise_pact
            .create_verification(provider_version: "4.5.6")
            .create_consumer_version("2.0.0")
            .create_pact
        end

        subject { Repository.new.find "Consumer", "Provider" }

        it "returns the latest revision of each pact in reverse consumer_version_order" do
          expect(subject.count).to eq 2
          expect(subject[0][:consumer_version_number]).to eq "2.0.0"
          expect(subject[1][:consumer_version_number]).to eq "1.2.3"
        end

        it "returns the latest verification for the pact version" do
          expect(subject[1][:provider_version]).to eq "4.5.6"
        end
      end
    end
  end
end
