require "pact_broker/versions/repository"
require "pact_broker/versions/branch_repository"

module PactBroker
  module Versions
    describe Repository do
      let(:pacticipant_name) { "test_pacticipant" }
      let(:version_number) { "1.2.3" }

      describe "#find_latest_by_pacticipant_name_and_branch_name" do
        before do
          td.create_consumer("Bar")
            .create_consumer_version("2.3.4", branch: "prod")
            .create_consumer("Foo")
            .create_consumer_version("1.2.3", branch: "prod")
            .create_consumer_version("2.3.4", branch: "prod")
            .create_consumer_version("5.6.7")
        end

        subject { Repository.new.find_latest_by_pacticipant_name_and_branch_name("Foo", "prod") }

        it "returns the most recent version from the specified branch for the specified pacticipant" do
          expect(subject.number).to eq "2.3.4"
          expect(subject.pacticipant.name).to eq "Foo"
        end
      end

      describe "#find_all_pacticipant_versions_in_reverse_order" do
        before do
          td
            .create_consumer("Foo")
            .create_consumer_version("1.2.3")
            .create_consumer_version("4.5.6")
            .create_consumer("Bar")
            .create_consumer_version("8.9.0")
        end

        subject { Repository.new.find_all_pacticipant_versions_in_reverse_order "Foo" }

        it "returns all the application versions for the given consumer" do
          expect(subject.collect(&:number)).to eq ["4.5.6", "1.2.3"]
        end

        context "with pagination options" do
          subject { Repository.new.find_all_pacticipant_versions_in_reverse_order "Foo", page_number: 1, page_size: 1 }

          it "paginates the query" do
            expect(subject.collect(&:number)).to eq ["4.5.6"]
          end
        end
      end

      describe "#find_pacticipant_versions_in_reverse_order" do
        before do
          td
            .create_consumer("Foo")
            .create_consumer_version("1", branch: "main")
            .create_consumer_version("2", branch: "foo")
            .create_consumer_version("3", branch: "main")
            .create_consumer("Bar")
            .create_consumer_version("5", branch: "main")
        end

        let(:options) { {} }
        subject { Repository.new.find_pacticipant_versions_in_reverse_order("Foo", options) }

        it "returns all the application versions for the given consumer" do
          expect(subject.collect(&:number)).to eq ["3", "2", "1"]
        end

        context "with a branch_name in the options" do
          let(:options) { { branch_name: "main"} }

          it "returns only the versions for the branch" do
            expect(subject.collect(&:number)).to eq ["3", "1"]
          end
        end

        context "with pagination options" do
          subject { Repository.new.find_pacticipant_versions_in_reverse_order "Foo", options, { page_number: 1, page_size: 1 } }

          it "paginates the query" do
            expect(subject.collect(&:number)).to eq ["3"]
          end
        end
      end

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
            td.create_version_with_hierarchy(pacticipant_name, version_number).and_return(:version)
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
          let!(:existing_version) { td.create_version_with_hierarchy(pacticipant_name, version_number).and_return(:version) }

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
          td.create_consumer("Foo")
            .create_consumer_version("1.2.3")
            .create_consumer_version("4.5.6")
            .and_return(:consumer_version)
        end

        subject { Repository.new.delete_by_id version.id }

        it "deletes the version" do
          expect { subject }.to change{ PactBroker::Domain::Version.count }.by(-1)
        end

        context "when the deleted version is the latest for a branch" do
          let!(:version) do
            td.create_consumer("Foo")
              .create_consumer_version("1.2.3", branch: "main")
              .create_consumer_version("4.5.6", branch: "main")
              .and_return(:consumer_version)
          end

          it "updates the branch head" do
            subject
            expect(td.find_pacticipant("Foo").branch_head_for("main").version.number).to eq "1.2.3"
          end
        end

        context "when the deleted version is the latest and last for a branch" do
          let!(:version) do
            td.create_consumer("Foo")
              .create_consumer_version("4.5.6", branch: "main")
              .and_return(:consumer_version)
          end

          it "leaves the branch, but deletes the branch head (not sure about this, but thinking the branch creation date is handy for the WIP/pending calculation)" do
            subject
            foo = td.find_pacticipant("Foo")
            expect(foo.branches.collect(&:name)).to include "main"
            expect(td.find_pacticipant("Foo").branch_head_for("main")).to be nil
          end
        end
      end

      describe "#delete_by_branch" do
        before do
          td.create_consumer("foo")
            .create_consumer_version("1234", branch: "main")
            .create_consumer_version("1234", branch: "foo") # 2nd branch
            .create_consumer_version("555", branch: "main")
            .create_consumer_version("777", branch: "blah")
            .create_consumer("bar")
            .create_consumer_version("1234", branch: "main")
        end

        let(:branch) { PactBroker::Versions::BranchRepository.new.find_branch(pacticipant_name: "foo", branch_name: "main") }

        subject { Repository.new.delete_by_branch(branch) }

        it "deletes versions that belong only to the branch that is being deleted" do
          expect(td.find_version("foo", "555")).to_not be_nil
          expect { subject }.to change { PactBroker::Domain::Version.count }.by(-1)
          expect(td.find_version("foo", "555")).to be_nil
        end

        it "only deletes the branch_versions associated with the versions that were deleted" do
          expect{ subject }.to change { PactBroker::Versions::BranchVersion.count }.by(-1)
        end
      end

      describe "#find_by_pacticipant_name_and_number" do

        subject { described_class.new.find_by_pacticipant_name_and_number pacticipant_name, version_number }

        context "when the version exists" do
          before do
            td.create_consumer("Another Consumer")
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

      describe "#create_or_update" do
        before do
          td.subtract_day
            .create_consumer("Foo")
            .create_consumer_version(version_number, branch: "original-branch", build_url: "original-build-url")
            .create_consumer_version_tag("dev")
        end

        let(:pacticipant) { td.and_return(:consumer) }
        let(:version_number) { "1234" }
        let(:tags) { nil }
        let(:open_struct_version) { OpenStruct.new(build_url: new_build_url, tags: tags) }
        let(:new_build_url) { "new-build-url" }

        subject { Repository.new.create_or_update(pacticipant, version_number, open_struct_version) }

        context "with empty properties" do
          let(:open_struct_version) { OpenStruct.new }

          it "does not overwrite missing values the values" do
            expect(subject.build_url).to eq "original-build-url"
          end

          it "does not change the tags" do
            expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").tags }
          end
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
        let(:open_struct_version) { OpenStruct.new(tags: tags) }

        subject { Repository.new.create_or_overwrite(pacticipant, version_number, open_struct_version) }

        it "overwrites the values" do
          expect(subject.branch_names).to eq ["original-branch"]
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
