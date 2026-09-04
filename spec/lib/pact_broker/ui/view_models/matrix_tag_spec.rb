require "pact_broker/ui/view_models/matrix_tag"

module PactBroker
  module UI
    module ViewModels
      describe MatrixTag do
        let(:tag_params) do
          {
            name: "prod",
            pacticipant_name: "Foo",
            version_number: "1.0.0",
            created_at: DateTime.now - 1,
            latest: true,
            base_url: base_url
          }
        end
        let(:base_url) { "" }

        subject(:matrix_tag) { MatrixTag.new(tag_params) }

        its(:name) { is_expected.to eq "prod" }
        its(:pacticipant_name) { is_expected.to eq "Foo" }
        its(:version_number) { is_expected.to eq "1.0.0" }

        describe "#url" do
          context "without base_url" do
            let(:base_url) { "" }

            it "returns a HAL browser URL with the tag path" do
              expect(subject.url).to eq "/hal-browser/browser.html#/pacticipants/Foo/versions/1.0.0/tags/prod"
            end
          end

          context "with base_url" do
            let(:base_url) { "/pact-broker-api" }

            it "returns a HAL browser URL with the base_url prefix" do
              expect(subject.url).to eq "/pact-broker-api/hal-browser/browser.html#/pact-broker-api/pacticipants/Foo/versions/1.0.0/tags/prod"
            end
          end

          context "with full base_url including host" do
            let(:base_url) { "http://example.org" }

            it "returns a HAL browser URL with the full base_url" do
              expect(subject.url).to eq "http://example.org/hal-browser/browser.html#http://example.org/pacticipants/Foo/versions/1.0.0/tags/prod"
            end
          end
        end

        describe "#tooltip" do
          context "when tag is latest" do
            it "includes 'latest version' in the tooltip" do
              expect(subject.tooltip).to include("This is the latest version of Foo with tag \"prod\"")
            end
          end

          context "when tag is not latest" do
            let(:tag_params) do
              {
                name: "prod",
                pacticipant_name: "Foo",
                version_number: "1.0.0",
                created_at: DateTime.now - 1,
                latest: false,
                base_url: ""
              }
            end

            it "indicates a more recent version exists" do
              expect(subject.tooltip).to include("A more recent version of Foo with tag \"prod\" exists")
            end
          end
        end
      end
    end
  end
end
