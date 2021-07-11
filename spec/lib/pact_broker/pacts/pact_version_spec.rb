require "pact_broker/pacts/pact_version"

module PactBroker
  module Pacts
    describe PactVersion do

      describe "pacticipant names" do
        subject(:pact_version) do
          TestDataBuilder.new
            .create_consumer("consumer")
            .create_provider("provider")
            .create_consumer_version("1.0.1")
            .create_pact
          PactVersion.order(:id).last
        end

        its(:consumer_name) { is_expected.to eq("consumer") }
        its(:provider_name) { is_expected.to eq("provider") }
      end

      describe "#latest_pact_publication" do

        context "when the latest pact publication is not an overwritten one" do
          before do
            TestDataBuilder.new
              .create_provider("Bar")
              .create_consumer("Foo")
              .create_consumer_version("1.2.100")
              .create_pact
              .revise_pact
              .create_consumer_version("1.2.101")
              .create_pact
              .create_consumer_version("1.2.102")
              .create_pact
              .revise_pact
              .create_provider("Animals")
              .create_pact
              .create_provider("Wiffles")
              .create_pact
          end

          it "returns the latest pact publication for the given pact version" do
            pact = PactBroker::Pacts::Repository.new.find_pact("Foo", "1.2.102", "Animals")
            pact_version = PactBroker::Pacts::PactVersion.find(sha: pact.pact_version_sha)
            latest_pact_publication = pact_version.latest_pact_publication
            expect(latest_pact_publication.id).to eq pact.id
          end
        end

        context "when the only pact publication with the given sha is an overwritten one" do
          let(:td) { TestDataBuilder.new }
          let!(:first_version) do
            td.create_provider("Bar")
              .create_consumer("Foo")
              .create_consumer_version("1")
              .create_pact
              .and_return(:pact)
          end
          let!(:second_revision) do
            td.revise_pact
          end

          it "returns the overwritten pact publication" do
            pact_version = PactBroker::Pacts::PactVersion.find(sha: first_version.pact_version_sha)
            latest_pact_publication = pact_version.latest_pact_publication
            expect(latest_pact_publication.revision_number).to eq 1
          end
        end
      end

      describe "#latest_consumer_version_number" do
        before do
          PactBroker.configuration.order_versions_by_date = false
          builder = TestDataBuilder.new
          builder
            .create_consumer
            .create_provider
            .create_consumer_version("1.0.1")
            .create_pact
            .create_consumer_version("1.0.0")
            second_consumer_version = builder.and_return(:consumer_version)
            pact_publication = PactBroker::Pacts::PactPublication.order(:id).last
            new_params = pact_publication.to_hash
            new_params.delete(:id)
            new_params[:revision_number] = 2
            new_params[:consumer_version_id] = second_consumer_version.id

            PactBroker::Pacts::PactPublication.create(new_params)
        end

        it "returns the latest consumer version that has a pact that has this content" do
          expect(PactVersion.first.latest_consumer_version_number).to eq "1.0.1"
        end
      end

      describe "#latest_verification" do
        before do
          td.create_pact_with_hierarchy
            .create_verification(provider_version: "4", number: 1)
            .create_verification(provider_version: "5", number: 2)
            .create_verification(provider_version: "6", number: 3)
            .create_pact_with_hierarchy
            .create_verification
            .create_verification(provider_version: "1", number: 2)
            .create_verification(provider_version: "2", number: 3)
        end

        describe "lazy loading" do
          let(:pact_version) { PactVersion.last }

          subject { pact_version.latest_verification }

          it "returns the latest verification by verification id" do
            expect(subject.number).to eq 3
          end
        end

        describe "eager loading" do
          let(:first_pact_latest_verification) { PactVersion.eager(:latest_verification).order(:id).all.first.associations[:latest_verification] }
          let(:last_pact_latest_verification) { PactVersion.eager(:latest_verification).order(:id).all.last.associations[:latest_verification] }

          it "returns the latest verification by verification id" do
            expect(first_pact_latest_verification.number).to eq 3
            expect(first_pact_latest_verification.provider_version_number).to eq "6"
            expect(last_pact_latest_verification.number).to eq 3
            expect(last_pact_latest_verification.provider_version_number).to eq "2"
          end
        end
      end

      describe "select_provider_tags_with_successful_verifications" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
            .create_verification(provider_version: "21", number: 2)
        end

        let(:pact_version) { PactVersion.last }
        let(:tags) { %w[dev] }

        subject { pact_version.select_provider_tags_with_successful_verifications(tags) }

        context "when the pact version has been successfully verified by all the specified tags" do
          let(:tags) { %w[dev] }

          it { is_expected.to eq tags }
        end

        context "when the pact version has been verified successfully by one the two specified tags" do
          let(:tags) { %w[dev feat-foo] }

          it { is_expected.to eq %w[dev] }
        end

        context "when the pact version has been verified unsuccessfully by all of the specified tags" do
          before do
            td.create_verification(provider_version: "30", number: 10, tag_names: ["feat-bar"], success: false)
          end

          let(:tags) { %w[feat-bar] }

          it { is_expected.to eq [] }
        end
      end

      describe "select_provider_tags_with_successful_verifications_from_another_branch_from_before_this_branch_created" do
        let(:pact_version) { PactVersion.last }

        subject { pact_version.select_provider_tags_with_successful_verifications_from_another_branch_from_before_this_branch_created(tags) }

        context "when the provider version tag specified does not exist yet but there are previous successful verifications from another branch" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
              .create_verification(provider_version: "21", number: 2)
          end

          let(:tags) { %w[feat-new-branch] }

          it { is_expected.to eq ["feat-new-branch"] }
        end

        context "when there is a successful verification from before the first provider version with the specified tag was created" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
              .add_day
              .create_verification(provider_version: "21", tag_names: ["feat-new-branch"], number: 2, success: false)
          end

          let(:tags) { %w[feat-new-branch] }

          it { is_expected.to eq ["feat-new-branch"] }
        end

        context "when there is a successful verification from after the first provider version with the specified tag was created" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "21", tag_names: ["feat-new-branch"], number: 2, success: false)
              .add_day
              .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
          end

          let(:tags) { %w[feat-new-branch] }

          it { is_expected.to eq [] }
        end
      end

      describe "#verified_successfully_by_any_provider_version?" do

        let(:pact_version) { PactVersion.last }

        subject { pact_version.verified_successfully_by_any_provider_version? }

        context "when the pact version has been successfully verified before" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "20", success: true)
              .create_verification(provider_version: "21", number: 2, success: false)
          end

          it { is_expected.to be true }
        end

        context "when the pact version has been unsuccessfully verified before" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "21", number: 2, success: false)
          end

          it { is_expected.to be false }
        end

        context "when the pact version has not been verified ever before" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
          end

          it { is_expected.to be false }
        end
      end
    end
  end
end
