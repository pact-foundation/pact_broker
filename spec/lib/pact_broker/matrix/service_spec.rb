require 'pact_broker/matrix/service'

module PactBroker
  module Matrix
    describe Service do
      let(:td) { TestDataBuilder.new }

      describe "validate_selectors" do

        subject { Service.validate_selectors(selectors) }

        context "when there are no selectors" do
          let(:selectors) { [] }

          it "returns error messages" do
            expect(subject.first).to eq "Please provide 1 or more version selectors."
          end
        end

        context "when one or more of the selectors does not match any known version" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1")
              .create_pacticipant("Bar")
              .create_version("2")
          end

          let(:selectors) { [{ pacticipant_name: "Foo", pacticipant_version_number: "1" }, { pacticipant_name: "Bar", pacticipant_version_number: "1" }] }

          it "returns error messages" do
            expect(subject).to eq ["No pact or verification found for Bar version 1"]
          end
        end

        context "when the pacticipant does not exist" do
          let(:selectors) { [{ pacticipant_name: "Foo", pacticipant_version_number: "1" }] }

          it "returns error messages" do
            expect(subject.first).to eq "Pacticipant 'Foo' not found"
          end
        end

        context "when the pacticipant name is not specified" do
          let(:selectors) { [{ pacticipant_name: nil, pacticipant_version_number: "1" }] }

          it "returns error messages" do
            expect(subject.first).to eq "Please specify the pacticipant name"
          end
        end

        context "when the pacticipant version is not specified" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1")
              .create_pacticipant("Bar")
              .create_version("2")
          end

          let(:selectors) { [ { pacticipant_name: "Foo", pacticipant_version_number: nil }, { pacticipant_name: "Bar", pacticipant_version_number: nil } ] }

          it "returns no error messages" do
            expect(subject).to eq []
          end
        end

        context "when the pacticipant name and version are not specified" do
          let(:selectors) { [{ pacticipant_name: nil, pacticipant_version_number: nil }] }

          it "returns error messages" do
            expect(subject.first).to eq "Please specify the pacticipant name and version"
          end
        end
      end
    end
  end
end
