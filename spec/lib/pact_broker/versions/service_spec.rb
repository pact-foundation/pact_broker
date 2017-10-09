require 'pact_broker/versions/service'

module PactBroker

  module Versions
    describe Service do

      describe ".find_versions_by_selector" do

        context "without a version selector" do
          let(:selector) { "Foo" }
        end

        context "with a version selector" do
          before do
            TestDataBuilder.new
              .create_pacticipant("Foo")
              .create_version("1.2.3")
              .create_version("4.5.6")
              .create_pacticipant("Bar")
              .create_version("1.2.3")
          end

          let(:selector) { "Foo/version/1.2.3" }

          subject { Service.find_versions_by_selector [selector] }

          context "when the version exists" do
            it "returns the specfied version" do
              expect(subject.first.number).to eq "1.2.3"
              expect(subject.first.pacticipant.name).to eq "Foo"
            end
          end

          context "when the version does not exist" do
            let(:selector) { "Wiffle/version/0.0.0" }

            it "returns nil" do
              expect(subject.first).to eq nil
            end
          end
        end
      end

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
