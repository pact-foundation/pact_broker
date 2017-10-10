require 'pact_broker/matrix/service'

module PactBroker
  module Matrix
    describe Service do
      describe "validate_selectors" do
        let(:td) { TestDataBuilder.new }

        subject { Service.validate_selectors(selectors) }

        context "when a selector format is invalid" do
          let(:selectors) { ["Foo/1"] }

          it "returns error messages" do
            expect(subject.first).to eq "Invalid version selector 'Foo/1'. Format must be <pacticipant_name>/version/<version>"
          end
        end

        context "when one or more of the selectors does not match any known version" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1")
              .create_pacticipant("Bar")
              .create_version("2")

          end

          let(:selectors) { ["Foo/version/1", "Bar/version/1"] }

          it "returns error messages" do
            expect(subject).to eq ["No pact or verification found for Bar/version/1"]
          end
        end

        context "when the pacticipant does not exist" do
          let(:selectors) { ["Foo/version/1"] }

          it "returns error messages" do
            expect(subject.first).to eq "Pacticipant 'Foo' not found"
          end
        end
      end
    end
  end
end

