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
            expect(subject.first).to eq "Pacticipant Foo not found"
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

        context "when the latest_tag is used instead of a version" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1")
              .create_tag("prod")
              .create_pacticipant("Bar")
              .create_version("2")
          end

          let(:selectors) { [{ pacticipant_name: "Foo", latest_tag: "prod" }, { pacticipant_name: "Bar", pacticipant_version_number: "2" }] }

          context "when there is a version for the tag" do
            it "returns no error messages" do
              expect(subject).to eq []
            end
          end

          context "when there is not a version for the tag" do

            let(:selectors) { [{ pacticipant_name: "Foo", latest: true, tag: "wiffle" }, { pacticipant_name: "Bar", pacticipant_version_number: "2" }] }

            it "returns an error message" do
              expect(subject).to eq ["No version of Foo found with tag wiffle"]
            end
          end
        end

        context "when the latest is used as well as a version" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1")
              .create_tag("prod")
              .create_pacticipant("Bar")
              .create_version("2")
          end

          let(:selectors) { [{ pacticipant_name: "Foo", pacticipant_version_number: "1", latest: true }, { pacticipant_name: "Bar", pacticipant_version_number: "2" }] }

          it "returns an error message" do
            expect(subject).to eq ["A version and latest flag cannot both be specified for Foo"]
          end
        end

        context "when a tag is specified without latest=true" do
          before do
            td.create_pacticipant("Foo")
              .create_version("1")
              .create_tag("prod")
              .create_pacticipant("Bar")
              .create_version("2")
          end

          let(:selectors) { [{ pacticipant_name: "Foo", tag: "1"}] }

          it "returns an error message" do
            expect(subject).to eq ["Querying for all versions with a tag is not currently supported. The latest=true flag must be specified when a tag is given."]
          end
        end
      end
    end
  end
end
