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
            expect(subject).to eq ["A version number and latest flag cannot both be specified for Foo"]
          end
        end
      end

      describe "find_for_consumer_and_provider_with_tags integration test" do

        let(:params) do
          {
            consumer_name: 'consumer',
            provider_name: 'provider',
            tag: 'prod',
            provider_tag: 'master'
          }
        end

        subject { Service.find_for_consumer_and_provider_with_tags(params) }

        context "when the specified row exists" do
          before do
            td.create_pact_with_hierarchy('consumer', '1', 'provider')
              .create_consumer_version_tag('prod')
              .create_verification(provider_version: '2')
              .use_provider_version('2')
              .create_provider_version_tag('master')
              .create_verification(provider_version: '3', number: 2)
              .create_consumer_version('2')
              .create_pact
          end

          it "returns the row" do
            expect(subject.consumer_name).to eq 'consumer'
            expect(subject.provider_name).to eq 'provider'
            expect(subject.consumer_version_number).to eq '1'
            expect(subject.provider_version_number).to eq '2'
          end
        end

        context "when the specified row does not exist" do
          it "returns nil" do
            expect(subject).to be nil
          end
        end
      end
    end
  end
end
