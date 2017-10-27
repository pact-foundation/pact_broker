require 'pact_broker/matrix/service'

module PactBroker
  module Matrix
    describe Service do
      let(:td) { TestDataBuilder.new }

      describe "validate_selectors" do

        subject { Service.validate_selectors(selectors) }


        context "when there is only one selector" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1")
          end

          let(:selectors) { {"Foo" => "1"} }

          it "returns error messages" do
            expect(subject.first).to eq "Please provide 2 or more version selectors."
          end
        end

        context "when one or more of the selectors does not match any known version" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1")
              .create_pacticipant("Bar")
              .create_version("2")

          end

          let(:selectors) { {"Foo" => "1", "Bar" => "1"} }

          it "returns error messages" do
            expect(subject).to eq ["No pact or verification found for Bar version 1"]
          end
        end

        context "when the pacticipant does not exist" do
          let(:selectors) { {"Foo" => "1"} }

          it "returns error messages" do
            expect(subject.first).to eq "Pacticipant 'Foo' not found"
          end
        end

        context "when the pacticipant name is not specified" do
          let(:selectors) { {nil => "1"} }

          it "returns error messages" do
            expect(subject.first).to eq "Please specify the pacticipant name"
          end
        end

        context "when the pacticipant version is not specified" do
          let(:selectors) { {'Foo' => nil} }

          it "returns error messages" do
            expect(subject.first).to eq "Please specify the version for Foo"
          end
        end

        context "when the pacticipant name and version are not specified" do
          let(:selectors) { {nil => nil} }

          it "returns error messages" do
            expect(subject.first).to eq "Please specify the pacticipant name and version"
          end
        end
      end
    end
  end
end
