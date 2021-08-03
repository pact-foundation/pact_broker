require "spec_helper"
require "pact_broker/tags/service"

module PactBroker
  module Tags
    describe Service do
      before do
        allow(PactBroker.configuration).to receive(:use_first_tag_as_branch).and_return(use_first_tag_as_branch)
      end
      let(:pacticipant_name) { "test_pacticipant" }
      let(:version_number) { "1.2.3" }
      let(:tag_name) { "prod" }
      let(:options) { { pacticipant_name: pacticipant_name, pacticipant_version_number: version_number, tag_name: tag_name }}
      let(:use_first_tag_as_branch) { false }


      describe ".create" do
        subject { Service.create(options) }

        it "creates the new tag" do
          expect(subject.name).to eq tag_name
          expect(subject.version.number).to eq version_number
          expect(subject.version.pacticipant.name).to eq pacticipant_name
        end

        context "when use_first_tag_as_branch_time_limit is true" do
          let(:use_first_tag_as_branch) { true }

          context "when there is already a tag" do
            before do
              td.create_consumer(pacticipant_name)
                .create_consumer_version(version_number, tag_name: "foo")
            end

            it "does not set the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch).to be_nil
            end
          end

          context "when the branch is already set" do
            before do
              td.create_consumer(pacticipant_name)
                .create_consumer_version(version_number, branch: "foo")
            end

            it "does not update the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch).to eq "foo"
            end
          end

          context "when use_first_tag_as_branch is false" do
            let(:use_first_tag_as_branch) { false }

            it "does not set the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch).to be_nil
            end
          end

          context "when the version was outside of the time difference limit" do
            before do
              version = td.create_consumer(pacticipant_name)
                .create_consumer_version(version_number)
                .and_return(:consumer_version)

              version.update(created_at: created_at)
              allow(PactBroker.configuration).to receive(:use_first_tag_as_branch_time_limit).and_return(10)
              allow(Time).to receive(:now).and_return(td.in_utc { Time.new(2021, 1, 2, 10, 10, 11) } )
            end

            let(:created_at) { td.in_utc { Time.new(2021, 1, 2, 10, 10, 0) }.to_datetime  }

            let(:one_second) { 1/(24 * 60 * 60) }

            it "does not set the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch).to be_nil
            end
          end

          context "when the version was created within the limit" do
            before do
              version = td.create_consumer(pacticipant_name)
                .create_consumer_version(version_number)
                .and_return(:consumer_version)

              version.update(created_at: created_at)
              allow(PactBroker.configuration).to receive(:use_first_tag_as_branch_time_limit).and_return(10)
              allow(Time).to receive(:now).and_return(td.in_utc { Time.new(2021, 1, 2, 10, 10, 10) } )
            end

            let(:created_at) { td.in_utc { Time.new(2021, 1, 2, 10, 10, 0) }.to_datetime  }
            let(:one_second) { 1/(24 * 60 * 60) }

            it "sets the branch" do
              subject
              expect(td.find_version(pacticipant_name, version_number).branch).to eq "prod"
            end
          end
        end
      end

      describe "delete" do

        let(:second_pacticipant_name) { "second_test_pacticipant" }
        let(:second_version_number) { "4.5.6" }
        let(:second_options_same_tag_name) { { pacticipant_name: second_pacticipant_name, pacticipant_version_number: second_version_number, tag_name: tag_name }}

        before do
          Service.create(options)
          Service.create(second_options_same_tag_name)
        end

        let(:delete_tag_for_particpant_and_version) { subject.delete second_options_same_tag_name}

        it "deletes the tag for the particpiant and the version" do
          expect{ delete_tag_for_particpant_and_version }.to change{
            PactBroker::Domain::Tag.all.count
          }.by(-1)
        end
      end
    end
  end
end