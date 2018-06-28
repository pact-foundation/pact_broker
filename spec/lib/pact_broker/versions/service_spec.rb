require 'pact_broker/versions/service'

module PactBroker

  module Versions
    describe Service do
      describe ".delete" do
        let(:td) { TestDataBuilder.new }
        let!(:version) do
          td
            .create_consumer
            .create_provider
            .create_consumer_version("1.2.3")
            .create_consumer_version_tag("prod")
            .create_pact
            .create_verification(provider_version: "1.0.0")
            .and_return(:consumer_version)
        end

        subject { Service.delete(version) }

        it "deletes the pact publication" do
          expect{ subject }.to change { PactBroker::Pacts::PactPublication.count }.by(-1)
        end

        it "deletes the tags" do
          expect{ subject }.to change { PactBroker::Domain::Tag.count }.by(-1)
        end

        it "deletes the version" do
          expect{ subject }.to change { PactBroker::Domain::Version.count }.by(-1)
        end

        context "when deleting a provider version" do
          it "deletes associated verifications" do
            expect { Service.delete(td.provider_version ) }. to change { PactBroker::Domain::Verification.count }.by(-1)
          end
        end
      end
    end
  end
end
