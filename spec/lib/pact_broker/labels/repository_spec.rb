require "spec_helper"
require "pact_broker/labels/repository"

module PactBroker
  module Labels
    describe Repository do

      describe ".find" do

        let(:pacticipant_name) { "foo" }
        let(:label_name) { "ios" }

        subject { Repository.new }
        let(:options) { {pacticipant_name: pacticipant_name, label_name: label_name} }
        let(:find_label) { subject.find options }

        let!(:test_data_builder) do
          TestDataBuilder.new
            .create_pacticipant("wiffle")
            .create_label(label_name)
            .create_pacticipant(pacticipant_name)
            .create_label("wrong label")
        end

        context "when the label exists" do

          before do
            test_data_builder.create_label(label_name)
          end

          it "returns the label" do
            expect(find_label.name).to eq label_name
            expect(find_label.pacticipant.name).to eq pacticipant_name
            expect(find_label.created_at).to be_datey
            expect(find_label.updated_at).to be_datey
          end

          context "when case sensitivity is turned off and a name with different case is used" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
            end

            let(:options) { {pacticipant_name: pacticipant_name.upcase, label_name: label_name.upcase} }

            it "returns the label" do
              expect(find_label).to_not be nil
              expect(find_label.name).to eq label_name
            end
          end

          context "when case sensitivity is turned on and a label name with different case is used" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(true)
            end

            let(:options) { {pacticipant_name: pacticipant_name, label_name: label_name.upcase} }

            it "returns nil" do
              expect(find_label).to be nil
            end
          end

          context "when case sensitivity is turned on and a pacticipant name with different case is used" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(true)
            end

            let(:options) { {pacticipant_name: pacticipant_name.upcase, label_name: label_name} }

            it "returns nil" do
              expect(find_label).to be nil
            end
          end
        end

        context "when the tag does not exist" do
          it "returns nil" do
            expect(find_label).to be_nil
          end
        end
      end

      describe "delete" do
        let(:pacticipant_name) { "foo" }
        let(:label_name) { "ios" }

        let!(:pacticipant) do
          TestDataBuilder.new
            .create_pacticipant("Ignore")
            .create_label("ios")
            .create_pacticipant(pacticipant_name)
            .create_label("ios")
            .create_label("bar")
            .and_return(:pacticipant)
        end
        let(:options) { {pacticipant_name: pacticipant_name, label_name: label_name} }

        subject { Repository.new.delete(options) }

        it "deletes the label" do
          expect{ subject }.to change { PactBroker::Domain::Label.count }.by(-1)
        end
      end

      describe "delete_by_pacticipant_id" do
        let!(:pacticipant) do
          TestDataBuilder.new
            .create_pacticipant("Ignore")
            .create_label("ios")
            .create_pacticipant("Foo")
            .create_label("ios")
            .create_label("bar")
            .and_return(:pacticipant)
        end

        subject { Repository.new.delete_by_pacticipant_id(pacticipant.id) }

        it "deletes the labels" do
          expect{ subject }.to change { PactBroker::Domain::Label.count }.by(-2)
        end
      end
    end
  end
end
