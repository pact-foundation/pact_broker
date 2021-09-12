module PactBroker
  module Pacts
    describe PactPublication do
      describe "#latest_verification_for_consumer_branches" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("1", branch: "main")
            .create_pact
            .create_verification(provider_version: "1")
            .create_verification(provider_version: "2", number: 2)
            .create_consumer_version("2", branch: "feat/x")
            .create_pact_with_different_content
            .create_verification(provider_version: "5")
            .create_verification(provider_version: "6", number: 2)
        end

        it "lazy_loads" do
          expect(PactPublication.order(:id).first.latest_verification_for_consumer_branches.provider_version_number).to eq "2"
          expect(PactPublication.order(:id).last.latest_verification_for_consumer_branches.provider_version_number).to eq "6"
        end

        it "does not eager load" do
          expect { PactPublication.eager(:latest_verification_for_consumer_branches).order(:id).all }.to raise_error NotImplementedError
        end
      end
    end
  end
end
