require "spec_helper"
require "pact_broker/versions/repository"

module PactBroker
  module Versions
    describe Repository do
      let(:pacticipant_name) { "test_pacticipant" }
      let(:version_number) { "1.2.3" }

      describe "#find_by_pacticipant_name_and_latest_tag" do
        before do
          td.create_consumer("Bar")
            .create_consumer_version("2.3.4")
            .create_consumer_version_tag("prod")
            .create_consumer("Foo")
            .create_consumer_version("1.2.3")
            .create_consumer_version_tag("prod")
            .create_consumer_version("2.3.4")
            .create_consumer_version_tag("prod")
            .create_consumer_version("5.6.7")
        end

        subject { Repository.new.find_by_pacticipant_name_and_latest_tag("Foo", "prod") }

        it "returns the most recent version that has the specified tag" do

          expect(subject.number).to eq "2.3.4"
          expect(subject.pacticipant.name).to eq "Foo"
        end
      end

      describe "#create" do
        context "when a previous version exists" do
          let!(:existing_version) do
            TestDataBuilder.new.create_version_with_hierarchy(pacticipant_name, version_number).and_return(:version)
          end

          subject { Repository.new.create pacticipant_id: existing_version.pacticipant_id, number: "1.2.4" }

          it "creates a new version" do
            expect { subject }.to change { PactBroker::Domain::Version.count }.by(1)
          end

          it "sets the order to the previous version's order plus one" do
            expect(subject.order).to eq existing_version.order + 1
          end
        end

        context "when the same version already exists" do
          let!(:existing_version) { TestDataBuilder.new.create_version_with_hierarchy(pacticipant_name, version_number).and_return(:version) }

          subject { Repository.new.create pacticipant_id: existing_version.pacticipant_id, number: version_number }

          it "does not create a new version" do
            expect { subject }.to_not change { PactBroker::Domain::Version.count }
          end

          it "returns the pre-existing version" do
            expect(subject.id).to eq existing_version.id
          end
        end
      end

      describe "#delete_by_id" do
        let!(:version) do
          TestDataBuilder.new
            .create_consumer
            .create_consumer_version("1.2.3")
            .create_consumer_version("4.5.6")
            .and_return(:consumer_version)
        end

        subject { Repository.new.delete_by_id version.id }

        it "deletes the version" do
          expect { subject }.to change{ PactBroker::Domain::Version.count }.by(-1)
        end
      end

      describe "#find_by_pacticipant_name_and_number" do

        subject { described_class.new.find_by_pacticipant_name_and_number pacticipant_name, version_number }

        context "when the version exists" do
          before do
            TestDataBuilder.new
              .create_consumer("Another Consumer")
              .create_consumer(pacticipant_name)
              .create_consumer_version(version_number)
              .create_consumer_version_tag("prod")
              .create_consumer_version("1.2.4")
              .create_consumer("Yet Another Consumer")
              .create_consumer_version(version_number)
          end

          it "returns the version" do
            expect(subject.id).to_not be nil
            expect(subject.number).to eq version_number
            expect(subject.pacticipant.name).to eq pacticipant_name
            expect(subject.tags.first.name).to eq "prod"
            expect(subject.order).to_not be nil
          end

          context "when case sensitivity is turned off and names with different cases are used" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
            end

            subject { described_class.new.find_by_pacticipant_name_and_number pacticipant_name.upcase, version_number.upcase }

            it "returns the version" do
              expect(subject).to_not be nil
            end
          end
        end

        context "when the version doesn't exist" do
          it "returns nil" do
            expect(subject).to be_nil
          end
        end
      end

      describe "#create_or_overwrite" do
        before do
          td.subtract_day
            .create_consumer("Foo")
            .create_consumer_version(version_number, branch: "original-branch", build_url: "original-build-url")
            .create_consumer_version_tag("dev")
        end

        let(:pacticipant) { td.and_return(:consumer) }
        let(:version_number) { "1234" }
        let(:tags) { nil }
        let(:open_struct_version) { OpenStruct.new(branch: "new-branch", tags: tags) }

        subject { Repository.new.create_or_overwrite(pacticipant, version_number, open_struct_version) }

        it "overwrites the values" do
          expect(subject.branch).to eq "new-branch"
          expect(subject.build_url).to eq nil
        end

        it "does not change the tags" do
          expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").tags }
        end

        context "when there are tags specified" do
          let(:tags) { [ OpenStruct.new(name: "main")] }

          it "overwrites the tags" do
            expect(subject.tags.count).to eq 1
            expect(subject.tags.first.name).to eq "main"
          end
        end

        it "does not change the created date" do
          expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").created_at }
        end

        it "does change the updated date" do
          expect { subject }.to change { PactBroker::Domain::Version.for("Foo", "1234").updated_at }
        end

        it "maintains the order" do
          expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").order }
        end

        context "when the version does not already exist" do
          let(:version) { OpenStruct.new(number: "555", branch: "new-branch") }

          it "sets the order" do
            expect(subject.order).to_not be nil
          end
        end
      end

      describe "#find_latest_version_from_main_branch" do
        subject { Repository.new.find_latest_version_from_main_branch(td.find_pacticipant("Foo")) }

        context "when there is a version with the provider's configured main branch as the branch" do
          before do
            td.create_consumer("Foo", main_branch: "main")
              .create_consumer_version("1", branch: "main")
              .create_consumer_version("2", branch: "main")
              .create_consumer_version("3", tag_name: "main")
              .create_consumer_version("4", branch: "not-main")
          end

          its(:number) { is_expected.to eq "2" }
        end

        context "when there is a version with the provider's configured main branch as the tag" do
          before do
            td.create_consumer("Foo", main_branch: "main")
              .create_consumer_version("1", branch: "not-main")
              .create_consumer_version("2", branch: "not-main")
              .create_consumer_version("3", tag_name: "main")
              .create_consumer_version("4", branch: "not-main")
          end

          its(:number) { is_expected.to eq "3" }
        end

        context "when there are no versions with a matching branch or tag set" do
          before do
            td.create_consumer("Foo", main_branch: "main")
              .create_consumer_version("1", branch: "not-main")
              .create_consumer_version("2", tag_name: "not-main")
          end

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
