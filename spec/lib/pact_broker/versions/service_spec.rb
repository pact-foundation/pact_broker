require 'pact_broker/versions/service'

module PactBroker

  module Versions
    describe Service do

      describe ".delete" do
        let!(:version) do
          TestDataBuilder.new
            .create_consumer
            .create_provider
            .create_consumer_version("1.2.3")
            .create_consumer_version_tag("prod")
            .create_pact
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
      end
    end
  end
end
