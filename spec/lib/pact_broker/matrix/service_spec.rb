
module PactBroker
  module Matrix
    describe Service do
      describe "can-i-merge" do
        before do
          td.create_consumer("A", main_branch: "main_branch", version: "1")
            .create_provider("B", main_branch: "main_branch", version: "1")
            .create_pact_with_hierarchy("A", "1", "B")
            .create_verification(provider_version: "1", number: 1, success: false, branch: "main_branch")
            .create_verification(provider_version: "1", number: 2, success: true, branch: "main_branch")
            .create_verification(provider_version: "2", number: 3, success: true, branch: "dev")
        end
        
        let(:pacticipant_name_param) { "B" }
        
        subject { Service.can_i_merge(pacticipant_name: pacticipant_name_param) }
  
        context "for pacticipant that has verification on it's main branch" do
          let(:options) {
            {
              latest: true,
              main_branch: true,
              latestby: "cvp"
            }
          }
          
          let(:unresolved_selectors) {
            [
              PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "B", pacticipant_version_number: "1")
            ]
          }
    
          it "returns true because the mergeble status is true" do
            expect(subject).to be_truthy
          end
    
          it "calls the can_i_deploy method" do
            expect(Service).to receive(:can_i_deploy).with(unresolved_selectors, options).and_call_original
            subject
          end
        end
      end

      describe "validate_selectors" do
        before do
          allow(PactBroker::Deployments::EnvironmentService).to receive(:find_by_name).and_return(environment)
        end
        let(:environment) { double("environment") }

        subject { Service.validate_selectors(selectors, options) }

        let(:options) { { limit: "1" } }

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

          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: nil ), UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: nil) ] }

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

          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Foo", latest_tag: "prod"), UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2")] }

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

          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1", latest: true), UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2")] }

          it "returns an error message" do
            expect(subject).to eq ["A version number and latest flag cannot both be specified for Foo"]
          end
        end

        context "when both a to tag and an environment are specified" do
          let(:selectors) { [] }

          let(:options) do
            {
              tag: "prod",
              environment_name: "prod"
            }
          end

          it "returns an error message" do
            expect(subject.last).to include "Cannot specify more than"
          end
        end

        context "when both latest=true and an environment are specified" do
          let(:selectors) { [] }

          let(:options) do
            {
              latest: true,
              environment_name: "prod"
            }
          end

          it "returns an error message" do
            expect(subject.last).to include "Cannot specify both latest"
          end
        end

        context "when both main_branch=true and an environment are specified" do
          let(:selectors) { [] }

          let(:options) do
            {
              main_branch: true,
              environment_name: "prod"
            }
          end

          it "returns an error message" do
            expect(subject.last).to include "Cannot specify more than"
          end
        end

        context "when both main_branch=true and a tag are specified" do
          let(:selectors) { [] }

          let(:options) do
            {
              main_branch: true,
              tag: "prod"
            }
          end

          it "returns an error message" do
            expect(subject.last).to include "Cannot specify more than"
          end
        end

        context "when the environment does not exist" do
          let(:selectors) { [] }
          let(:environment) { nil }

          let(:options) do
            {
              environment_name: "prod"
            }
          end

          it "returns an error message" do
            expect(subject.last).to include "Environment with name 'prod' does not exist"
          end
        end

        context "when a pacticipant to ignore is missing a name" do
          let(:selectors) { [UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1")] }

          let(:options) do
            {
              ignore_selectors: [UnresolvedSelector.new(pacticipant_version_number: "1")]
            }
          end

          it "returns an error message" do
            expect(subject.last).to include "Please specify the pacticipant name to ignore"
          end
        end

        context "with an invalid limit" do
          let(:options) { { limit: "limit" } }
          let(:selectors) { [] }

          it "returns an error message" do
            expect(subject.last).to include "The limit"
          end
        end
      end

      describe "find_for_consumer_and_provider_with_tags integration test" do

        let(:params) do
          {
            consumer_name: "consumer",
            provider_name: "provider",
            tag: "prod",
            provider_tag: "master"
          }
        end

        subject { Service.find_for_consumer_and_provider_with_tags(params) }

        context "when the specified row exists" do
          before do
            td.create_pact_with_hierarchy("consumer", "1", "provider")
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "2")
              .use_provider_version("2")
              .create_provider_version_tag("master")
              .create_verification(provider_version: "3", number: 2)
              .create_consumer_version("2")
              .create_pact
          end

          it "returns the row" do
            expect(subject.consumer_name).to eq "consumer"
            expect(subject.provider_name).to eq "provider"
            expect(subject.consumer_version_number).to eq "1"
            expect(subject.provider_version_number).to eq "2"
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
