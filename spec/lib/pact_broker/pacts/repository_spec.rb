# Yes, I know this file is too bug, but cmd+shift+t is too useful!

require "pact_broker/pacts/repository"
require "pact_broker/pacts/pact_params"
require "pact_broker/versions/repository"
require "pact_broker/pacticipants/repository"

module PactBroker
  module Pacts
    describe Repository do

      let(:consumer_name) { "Consumer" }
      let(:provider_name) { "Provider" }

      describe "create" do
        let(:consumer) { Pacticipants::Repository.new.create name: "Consumer" }
        let(:provider) { Pacticipants::Repository.new.create name: "Provider" }
        let(:version) { PactBroker::Versions::Repository.new.create number: "1.2.3", pacticipant_id: consumer.id }
        let(:pact_version_sha) { "123" }
        let(:json_content) { { interactions: ["json"] }.to_json }

        let(:params) do
          {
            version_id: version.id,
            consumer_id: consumer.id,
            provider_id: provider.id,
            json_content: json_content,
            pact_version_sha: pact_version_sha,
            version: version
          }
        end

        subject { Repository.new.create(params) }

        it "saves the pact" do
          expect{ subject }.to change{ PactPublication.count }.by(1)
        end

        it "sets the consumer_id" do
          subject
          expect(PactPublication.first.consumer_id).to eq consumer.id
        end

        it "returns a Pact::Model" do
          expect(subject).to be_instance_of(PactBroker::Domain::Pact)
        end

        it "sets all the Pact::Model attributes" do
          expect(subject.consumer).to eq consumer
          expect(subject.provider).to eq provider
          expect(subject.consumer_version_number).to eq "1.2.3"
          expect(subject.consumer_version.number).to eq "1.2.3"
          expect(subject.json_content).to eq json_content
          expect(subject.created_at).to be_datey
        end

        it "creates a LatestPactPublicationIdForConsumerVersion" do
          expect{ subject }.to change { LatestPactPublicationIdForConsumerVersion.count }.by(1)
        end

        it "sets the created_at of the LatestPactPublicationIdForConsumerVersion to the same as the consumer version, because that's how pacts are ordered" do
          subject
          expect(LatestPactPublicationIdForConsumerVersion.first.created_at).to eq PactBroker::Domain::Version.find(number: subject.consumer_version_number).created_at
        end

        it "sets the interactions count" do
          subject
          expect(PactVersion.order(:id).last.interactions_count).to eq 1
        end

        it "sets the messages count" do
          subject
          expect(PactVersion.order(:id).last.messages_count).to eq 0
        end

        context "when a pact already exists with exactly the same content" do
          let(:another_version) { Versions::Repository.new.create number: "2.0.0", pacticipant_id: consumer.id }

          before do
            Repository.new.create(
              version_id: version.id,
              consumer_id: consumer.id,
              provider_id: provider.id,
              json_content: json_content,
              pact_version_sha: pact_version_sha,
              version: version
            )
          end

          subject do
            Repository.new.create(
              version_id: another_version.id,
              consumer_id: consumer.id,
              provider_id: provider.id,
              json_content: json_content,
              pact_version_sha: pact_version_sha,
              version: another_version
            )
          end

          it "does not the content" do
            expect_any_instance_of(Content).to_not receive(:sort)
            subject
          end

          it "creates a new PactPublication" do
            expect { subject }.to change{ PactPublication.count }.by(1)
          end

          it "reuses the same PactVersion to save room" do
            expect { subject }.to_not change{ PactVersion.count }
          end

          context "when there is a race condition and the pact version gets created by another request in between attempting to find and create" do
            before do
              allow(PactVersion).to receive(:find).and_return(nil)
            end

            it "doesn't blow up" do
              expect(PactVersion).to receive(:find)
              subject
            end
          end
        end

        context "when base_equality_only_on_content_that_affects_verification_results is true" do
          let(:another_version) { Versions::Repository.new.create number: "2.0.0", pacticipant_id: consumer.id }
          let(:sha_1) { "1" }
          let(:sha_2) { "1" }

          before do
            # PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = true
            # allow(PactBroker.configuration.sha_generator).to receive(:call).and_return(sha_1, sha_2)
            Repository.new.create(
              version_id: version.id,
              consumer_id: consumer.id,
              provider_id: provider.id,
              json_content: json_content,
              pact_version_sha: sha_1,
              version: version
            )
          end

          subject do
            Repository.new.create(
              version_id: another_version.id,
              consumer_id: consumer.id,
              provider_id: provider.id,
              json_content: json_content,
              pact_version_sha: sha_2,
              version: another_version
            )
          end

          context "when the sha is the same" do
            it "reuses the same PactVersion to save room" do
              expect { subject }.to_not change{ PactVersion.count }
            end
          end

          context "when the sha is not the same" do
            let(:sha_2) { "2" }

            it "creates a new PactVersion" do
              expect { subject }.to change{ PactVersion.count }.by(1)
            end
          end
        end

        context "when a pact already exists with the same content but with a different consumer/provider" do
          let(:another_version) { Versions::Repository.new.create number: "2.0.0", pacticipant_id: consumer.id }
          let(:another_provider) { Pacticipants::Repository.new.create name: "Provider2" }
          before do
            Repository.new.create(
              version_id: version.id,
              consumer_id: consumer.id,
              provider_id: another_provider.id,
              json_content: json_content,
              pact_version_sha: pact_version_sha,
              version: version
            )
          end

          subject do
            Repository.new.create(
              version_id: another_version.id,
              consumer_id: consumer.id,
              provider_id: provider.id,
              json_content: json_content,
              pact_version_sha: pact_version_sha,
              version: another_version
            )
          end

          it "does not reuse the same PactVersion" do
            expect { subject }.to change{ PactVersion.count }.by(1)
          end
        end

        context "when a pact already exists with different content" do
          let(:another_version) { Versions::Repository.new.create number: "2.0.0", pacticipant_id: consumer.id }

          before do
            Repository.new.create(
              version_id: version.id,
              consumer_id: consumer.id,
              provider_id: provider.id,
              json_content: {some_other: "json_content"}.to_json,
              pact_version_sha: pact_version_sha,
              version: version
            )
          end

          subject do
            Repository.new.create(
              version_id: another_version.id,
              consumer_id: consumer.id,
              provider_id: provider.id,
              json_content: json_content,
              pact_version_sha: "#{pact_version_sha}111",
              version: another_version
            )
          end

          it "creates a new PactVersion" do
            expect { subject }.to change{ PactVersion.count }.by(1)
          end
        end
      end

      describe "update" do

        let(:existing_pact) do
          td.create_consumer("A Consumer")
            .create_provider("A Provider")
            .create_consumer_version("1.2.3")
            .create_pact(pact_version_sha: pact_version_sha, json_content: original_json_content)
            .and_return(:pact)
        end
        let(:repository) { Repository.new }

        before do
          PactPublication
            .dataset
            .where(id: existing_pact.id)
            .update(created_at: created_at)
          PactVersion
            .dataset
            .update(created_at: created_at)
        end

        let(:created_at) { DateTime.new(2014, 3, 2) }

        let(:original_json_content) { {some: "json"}.to_json }
        let(:json_content) { {some_other: "json"}.to_json }
        let(:pact_version_sha) { "123" }
        let(:new_pact_version_sha) { "567" }

        context "when the pact_version_sha has changed" do
          subject { repository.update(existing_pact.id, json_content: json_content, pact_version_sha: new_pact_version_sha) }

          it "creates a new PactVersion" do
            expect { subject }.to change{ PactBroker::Pacts::PactPublication.count }.by(1)
          end

          it "creates a new PactVersion" do
            expect { subject }.to change{ PactBroker::Pacts::PactVersion.count }.by(1)
          end

          it "does not change the existing PactVersion" do
            existing_pvc = PactBroker::Pacts::PactVersion.order(:id).last
            subject
            existing_pvc_reloaded = PactBroker::Pacts::PactVersion.find(id: existing_pvc[:id])
            expect(existing_pvc_reloaded).to eq(existing_pvc)
          end

          it "updates the existing content on the returned model" do
            expect(subject.json_content).to eq json_content
          end

          it "sets the created_at timestamp" do
            expect(subject.created_at).to_not eq created_at
          end

          it "increments the revision_number by 1" do
            expect(subject.revision_number).to eq 2
          end

          context "when there is a race condition" do
            before do
              allow(repository).to receive(:next_revision_number) { | existing_pact | existing_pact.revision_number }
            end

            it "updates the existing row - yes this is destructive, by MySQL not supporting inner queries stops us doing a SELECT revision_number + 1" do
              # And if we're conflicting the time between the two publications is so small that nobody
              # can have depended on the content of the first pact
              expect { subject }.to_not change{ PactBroker::Pacts::PactPublication.count }
            end

            it "sets the content to the new content" do
              expect(subject.json_content).to eq json_content
            end
          end
        end

        context "when the pact_version_sha has not changed" do
          subject do
            repository.update(existing_pact.id,
              json_content: original_json_content,
              pact_version_sha: pact_version_sha
            )
          end

          it "does not create a new PactVersion" do
            expect { subject }.to_not change{ PactBroker::Pacts::PactPublication.count }
          end

          it "does not create a new PactVersion" do
            expect { subject }.to_not change{ PactBroker::Pacts::PactVersion.count }
          end

          it "the json_content is the same" do
            expect(subject.json_content).to eq original_json_content
          end

          it "does not update the created_at timestamp" do
            expect(subject.created_at.to_datetime).to eq created_at
          end
        end
      end

      describe "delete" do
        before do
          td.create_consumer(consumer_name)
            .create_consumer_version("1.2.3")
            .create_provider(provider_name)
            .create_pact
            .create_webhook
            .revise_pact
            .create_consumer_version("2.3.4")
            .create_pact
            .create_provider("Another Provider")
            .create_pact
        end

        let(:pact_params) { PactBroker::Pacts::PactParams.new(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.2.3") }

        subject { Repository.new.delete pact_params }

        it "deletes all PactPublication for the specified consumer version" do
          expect { subject }.to change { PactPublication.count }.by(-2)
        end

        it "does not delete the content because it may be used by another pact" do
          expect { subject }.to change { PactVersion.count }.by(0)
        end

      end

      describe "delete_by_version_id" do
        let!(:version) do
          td.create_consumer
            .create_provider
            .create_consumer_version("4.5.6")
            .create_pact
            .create_consumer_version("1.2.3")
            .create_pact
            .and_return(:consumer_version)
        end

        subject { Repository.new.delete_by_version_id(version.id) }

        it "deletes the pact publication" do
          expect{ subject }.to change { PactPublication.count }.by(-1)
        end

        it "does not delete the content because it may be used by another pact" do
          expect { subject }.to change { PactVersion.count }.by(0)
        end
      end

      describe "#find_all_pact_versions_between" do

        before do
          td.create_consumer(consumer_name)
            .create_consumer_version("1.2.3")
            .create_provider(provider_name)
            .create_pact
            .create_consumer_version("2.3.4")
            .create_consumer_version_tag("prod")
            .create_consumer_version_tag("branch")
            .create_pact
            .create_provider("Another Provider")
            .create_pact
        end

        subject { Repository.new.find_all_pact_versions_between(consumer_name, :and => provider_name) }

        it "returns the pacts between the specified consumer and provider" do
          expect(subject.size).to eq 2
          expect(subject.first.consumer.name).to eq consumer_name
          expect(subject.first.provider.name).to eq provider_name
          expect(subject.first.consumer_version.number).to eq "2.3.4"
          expect(subject.first.consumer_version.tags.count).to eq 2
        end

        context "with a tag" do
          subject { Repository.new.find_all_pact_versions_between(consumer_name, :and => provider_name, tag: "prod") }

          it "returns the pacts between the specified consumer and provider with the given tag" do
            expect(subject.size).to eq 1
            expect(subject.first.consumer_version.number).to eq "2.3.4"
          end
        end
      end

      describe "#delete_all_pact_publications_between" do

        before do
          td.create_consumer(consumer_name)
            .create_consumer_version("1.2.3")
            .create_provider(provider_name)
            .create_pact
            .revise_pact
            .comment("The overwritten pact needs to be deleted too")
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_consumer_version("2.3.4")
            .create_consumer_version_tag("prod")
            .create_consumer_version_tag("branch")
            .create_pact
            .create_provider("Another Provider")
            .create_pact
            .comment("This one won't be deleted")
        end

        subject { Repository.new.delete_all_pact_publications_between(consumer_name, :and => provider_name) }

        it "deletes the pacts between the specified consumer and provider" do
          expect { subject }.to change { PactPublication.count }.by(-3)
        end

        context "with a tag" do
          subject { Repository.new.delete_all_pact_publications_between(consumer_name, :and => provider_name, tag: "prod") }

          it "deletes the pacts between the specified consumer and provider with the given tag" do
            expect { subject }.to change { PactPublication.count }.by(-1)
          end
        end
      end

      describe "#find_latest_pacts_for_provider" do
        context "with no tag specified" do
          before do
            td.create_consumer(consumer_name)
              .create_consumer_version("1.0.0")
              .create_provider(provider_name)
              .create_pact
              .create_consumer_version("1.2.3")
              .create_pact
              .create_consumer("wiffle consumer")
              .create_consumer_version("4.0.0")
              .create_pact
              .create_consumer_version("4.5.6")
              .create_pact
              .create_provider("not the provider")
              .create_pact
          end

          subject { Repository.new.find_latest_pacts_for_provider provider_name }

          it "returns the pacts between the specified consumer and provider" do
            expect(subject.size).to eq 2
            expect(subject.first.consumer.name).to eq consumer_name
            expect(subject.first.provider.name).to eq provider_name
            expect(subject.first.consumer_version.number).to eq "1.2.3"
            expect(subject.first.json_content).to_not be nil
            expect(subject.last.consumer.name).to eq "wiffle consumer"
            expect(subject.last.tag).to eq nil
            expect(subject.last.overall_latest?).to be true
          end
        end

        context "with a tag specified" do
          before do
            td.create_consumer(consumer_name)
              .create_consumer_version("1.2.3")
              .create_consumer_version_tag("prod")
              .create_provider(provider_name)
              .create_pact
              .create_consumer_version("2.0.0")
              .create_pact
              .create_consumer("wiffle consumer")
              .create_consumer_version("4.5.6")
              .create_pact
              .create_consumer_version("5.0.0")
              .create_consumer_version_tag("prod")
              .create_consumer_version_tag("test")
              .create_pact
              .create_provider("not the provider")
              .create_pact
          end

          subject { Repository.new.find_latest_pacts_for_provider provider_name, "prod" }

          it "returns the pacts between the specified consumer and provider with the given consumer version tag" do
            expect(subject.size).to eq 2
            expect(subject.first.provider.name).to eq provider_name
            expect(subject.first.consumer.name).to eq consumer_name
            expect(subject.first.consumer_version.number).to eq "1.2.3"
            expect(subject.first.json_content).to_not be nil
            expect(subject.first.tag).to eq "prod"
            expect(subject.last.consumer.name).to eq "wiffle consumer"
            expect(subject.last.consumer_version.number).to eq "5.0.0"
            expect(subject.last.tag).to eq "prod"
            expect(subject.last.overall_latest?).to be false
          end
        end
      end

      describe "#find_pact_versions_for_provider" do
        context "with no tag specified" do
          before do
            td.create_consumer(consumer_name)
              .create_consumer_version("1.0.0")
              .create_provider(provider_name)
              .create_pact
              .create_consumer_version("1.2.3")
              .create_pact
              .create_consumer("wiffle consumer")
              .create_consumer_version("4.0.0")
              .create_pact
              .create_consumer_version("4.5.6")
              .create_pact
              .create_provider("not the provider")
              .create_pact
          end

          subject { Repository.new.find_pact_versions_for_provider provider_name }

          it "returns all the pact versions for the specified provider" do
            expect(subject.size).to eq 4
            expect(subject.first.provider.name).to eq provider_name
          end
        end

        context "with a tag specified" do
          before do
            td.create_consumer(consumer_name)
              .create_consumer_version("1")
              .create_consumer_version_tag("prod")
              .create_provider(provider_name)
              .create_pact
              .create_consumer_version("2")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_consumer_version("3")
              .create_pact
              .create_consumer("wiffle consumer")
              .create_consumer_version("10")
              .create_pact
              .create_consumer_version("11")
              .create_consumer_version_tag("prod")
              .create_consumer_version_tag("test")
              .create_pact
              .create_provider("not the provider")
              .create_pact
          end

          subject { Repository.new.find_pact_versions_for_provider provider_name, "prod" }

          it "returns the pacts between the specified provider with the given consumer tag" do
            expect(subject.size).to eq 3
            expect(subject.first.provider.name).to eq provider_name
            expect(subject.first.consumer.name).to eq consumer_name
            expect(subject.first.consumer_version.number).to eq "1"
            expect(subject[1].consumer_version.number).to eq "2"
            expect(subject.first.json_content).to_not be nil
            expect(subject.last.consumer.name).to eq "wiffle consumer"
            expect(subject.last.consumer_version.number).to eq "11"
          end
        end
      end

      describe "find_pact" do
        let!(:pact) do
          pact = td
            .create_consumer("Consumer")
            .create_consumer_version("1.2.2")
            .create_provider("Provider")
            .create_pact
            .create_consumer_version("1.2.4")
            .create_consumer_version_tag("prod")
            .create_pact
            .revise_pact
            .and_return(:pact)
          td
            .create_consumer_version("1.2.6")
            .create_pact
            .create_provider("Another Provider")
            .create_consumer_version("1.2.5")
            .create_pact
          pact
        end

        subject  { Repository.new.find_pact "Consumer", "1.2.4", "Provider" }

        it "finds the pact with the given version" do
          expect(subject.consumer.name).to eq "Consumer"
          expect(subject.provider.name).to eq "Provider"
          expect(subject.consumer_version_number).to eq "1.2.4"
          expect(subject.consumer_version.number).to eq "1.2.4"
          expect(subject.consumer_version.tags.first.name).to eq "prod"
          expect(subject.json_content).to_not be_nil
        end

        context "with no version" do
          subject  { Repository.new.find_pact("Consumer", nil, "Provider") }

          it "returns the latest pact" do
            expect(subject.consumer_version_number).to eq "1.2.6"
          end
        end

        context "with a pact_version_sha" do
          subject  { Repository.new.find_pact "Consumer", nil, "Provider", pact.pact_version_sha }

          it "finds the pact with the given pact_version_sha" do
            expect(subject.pact_version_sha).to eq pact.pact_version_sha
            expect(subject.consumer.name).to eq "Consumer"
            expect(subject.provider.name).to eq "Provider"
            expect(subject.consumer_version_number).to eq "1.2.4"
            expect(subject.revision_number).to eq 2
          end

          context "when there are multiple pact publications for the pact version" do
            before do
              # Double check the data is set up correctly...
              expect(pact_1.pact_version_sha).to eq(pact_2.pact_version_sha)
            end

            let!(:pact_1) { td.create_pact_with_hierarchy("Foo", "1", "Bar").and_return(:pact) }
            let!(:pact_2) { td.create_consumer_version("2").create_pact(json_content: pact_1.json_content).and_return(:pact) }

            let(:consumer_version_number) { nil }

            subject  { Repository.new.find_pact "Foo", consumer_version_number, "Bar", pact_1.pact_version_sha }

            it "returns the latest pact, ordered by consumer version order" do
              expect(subject.consumer_version_number).to eq "2"
            end

            context "when the consumer_version_number is specified too (from the URL metadata)" do
              let(:consumer_version_number) { "1" }

              it "returns the publication with the consumer version specified" do
                expect(subject.consumer_version_number).to eq "1"
              end
            end

            context "when the consumer_version_number is specified too (from the URL metadata) but it doesn't exist (anymore)" do
              let(:consumer_version_number) { "9" }

              it "returns the pact matching the sha with the latest consumer version" do
                expect(subject.consumer_version_number).to eq "2"
              end
            end

            # Not sure when this would happen
            context "when the consumer_version_number is specified too (from the URL metadata) and it exists but it doesn't match the sha" do
              before do
                td.create_pact_with_hierarchy("Foo", "8", "Bar")
              end

              let(:consumer_version_number) { "8" }

              it "returns the pact matching the sha with the latest consumer version" do
                expect(subject.consumer_version_number).to eq "2"
              end
            end

            context "when the pact has multiple revisions and goes back to a previous revision" do
              before do
                td.revise_pact
                  .revise_pact(pact_1.json_content)
              end

              it "returns the latest revision" do
                expect(subject.revision_number).to eq 3
              end
            end
          end
        end
      end

      describe "find_all_revisions" do
        before do
          td.create_pact_with_hierarchy("foo", "3.0.0", "bar")
            .revise_pact
            .create_pact_with_hierarchy(consumer_name, "1.2.3", provider_name)
            .revise_pact
            .create_consumer_version("4.5.6")
            .create_pact
        end

        subject { Repository.new.find_all_revisions consumer_name, "1.2.3", provider_name }

        it "returns all the revisions for the given pact version" do
          expect(subject.size).to eq 2
          expect(subject.first.consumer_name).to eq consumer_name
          expect(subject.first.revision_number).to eq 1
          expect(subject.last.revision_number).to eq 2
        end
      end

      describe "find_previous_pact" do
        before do
          td.create_consumer("Consumer")
            .create_consumer_version("1.2.2")
            .create_provider("Provider")
            .create_consumer_version_tag("a_tag")
            .create_pact
            .create_consumer_version("1.2.3")
            .create_pact
            .create_consumer_version("1.2.4")
            .create_consumer_version_tag("another_tag")
            .create_pact
            .create_consumer_version("1.2.5")
            .create_consumer_version_tag("a_tag")
            .create_pact
            .create_consumer_version("1.2.7")
            .create_consumer_version_tag("another_tag")
            .create_pact
            .create_provider("Another Provider")
            .create_consumer_version("1.2.6")
            .create_consumer_version_tag("a_tag")
            .create_pact
        end

        context "regardless of tag" do
          context "when a previous version with a pact exists" do

            let(:pact) { Repository.new.find_latest_pact "Consumer", "Provider", "another_tag" }

            subject  { Repository.new.find_previous_pact pact }

            it "finds the previous pact" do
              expect(subject.consumer_version_number).to eq "1.2.5"
            end

            it "sets the json_content" do
              expect(subject.json_content).to_not be nil
            end
          end
        end

        context "by tag" do
          context "when a previous version with a pact with a specific tag exists" do

            let(:pact) { Repository.new.find_latest_pact "Consumer", "Provider", "a_tag"  }

            subject  { Repository.new.find_previous_pact pact, "a_tag" }

            it "finds the previous pact" do
              expect(subject.consumer_version_number).to eq "1.2.2"
            end

            it "sets the json_content" do
              expect(subject.json_content).to_not be nil
            end
          end
        end

        context "that is untagged" do
          context "when a previous version with a an untagged pact exists" do

            let(:pact) { Repository.new.find_latest_pact "Consumer", "Provider"  }

            subject  { Repository.new.find_previous_pact pact, :untagged }

            it "finds the previous pact" do
              expect(subject.consumer_version_number).to eq "1.2.3"
            end

            it "sets the json_content" do
              expect(subject.json_content).to_not be nil
            end
          end
        end
      end

      describe "find_next_pact" do
        before do
          td.create_consumer("Consumer")
            .create_consumer_version("1.2.2")
            .create_provider("Provider")
            .create_pact
            .create_consumer_version("1.2.4")
            .create_pact
            .create_consumer_version("1.2.6")
            .create_pact
            .create_provider("Another Provider")
            .create_consumer_version("1.2.5")
            .create_pact
        end

        let(:pact) { Repository.new.find_pact "Consumer", "1.2.4", "Provider"  }

        subject  { Repository.new.find_next_pact pact }

        it "finds the next pact" do
          expect(subject.consumer_version_number).to eq "1.2.6"
        end

        it "sets the json_content" do
          expect(subject.json_content).to_not be nil
        end
      end

      describe "find_previous_distinct_pact" do

        let(:pact_content_version_1) { load_fixture("consumer-provider.json") }
        let(:pact_content_version_2) do
          hash = load_json_fixture("consumer-provider.json")
          hash["interactions"].first["foo"] = "bar" # Extra key in interactions will affect equality
          hash.to_json
        end
        let(:pact_content_version_3) {  load_fixture("consumer-provider.json") }
        let(:pact_content_version_4) do
          # Move description to end of hash, should not affect equality
          hash = load_json_fixture("consumer-provider.json")
          description = hash["interactions"].first.delete("description")
          hash["interactions"].first["description"] = description
          hash.to_json
        end

        before do
          td.create_consumer("Consumer")
            .create_provider("Provider")
            .create_consumer_version("1")
            .create_pact(json_content: pact_content_version_1)
            .create_consumer_version("2")
            .create_pact(json_content: pact_content_version_2)
            .create_consumer_version("3")
            .create_pact(json_content: pact_content_version_3)
            .create_consumer_version("4")
            .create_pact(json_content: pact_content_version_4)
          expect(pact_content_version_3).to_not eq pact_content_version_4
        end

        let(:pact) { Repository.new.find_pact "Consumer", "4", "Provider"  }

        subject  { Repository.new.find_previous_distinct_pact pact }

        context "when there is a previous distinct version" do
          it "returns the previous pact with different content" do
            expect(subject.consumer_version_number).to eq("2")
          end
          it "returns json_content" do
            expect(subject.json_content).to_not be nil
          end
        end

        context "when there isn't a previous distinct version" do
          let(:pact_content_version_2) { load_fixture("consumer-provider.json") }

          it "returns nil" do
            expect(subject).to be nil
          end
        end

      end

      describe "find_latest_pact" do
        context "with a tag" do
          context "when a version with a pact exists with the given tag" do
            before do
              td.create_consumer("Consumer")
                .create_consumer_version("2.3.4")
                .create_provider("Provider")
                .create_pact
                .create_consumer_version("1.2.3")
                .create_consumer_version_tag("prod")
                .create_pact
            end

            let(:latest_prod_pact) { Repository.new.find_latest_pact("Consumer", "Provider", "prod") }

            it "returns the pact for the latest tagged version" do
              expect(latest_prod_pact.consumer_version.number).to eq("1.2.3")
            end

            it "has JSON content" do
              expect(latest_prod_pact.json_content).to_not be nil
            end

            it "has timestamps" do
              expect(latest_prod_pact.created_at).to be_datey
            end
          end

        end

        context "without a tag" do
          context "when one or more versions of a pact exist without any tags" do
            before do
              td.create_consumer("Consumer")
                .create_provider("Provider")
                .create_consumer_version("1.0.0")
                .create_pact
                .create_consumer_version("1.2.3")
                .create_pact
                .create_consumer_version("2.3.4")
                .create_consumer_version_tag("prod")
                .create_pact
            end

            let(:pact) { Repository.new.find_latest_pact("Consumer", "Provider", :untagged) }

            it "returns the latest" do
              expect(pact.consumer_version.number).to eq("1.2.3")
            end

            it "has JSON content" do
              expect(pact.json_content).to_not be nil
            end

            it "has timestamps" do
              expect(pact.created_at).to be_datey
            end
          end

          context "when all versions have a tag" do
            before do
              td.create_consumer("Consumer")
                .create_provider("Provider")
                .create_consumer_version("2.3.4")
                .create_consumer_version_tag("prod")
                .create_pact
            end

            let(:pact) { Repository.new.find_latest_pact("Consumer", "Provider", :untagged) }

            it "returns nil" do
              expect(pact).to be nil
            end
          end
        end
      end

      describe "search_for_latest_pact" do
        context "when one or more versions of a pact exist without any tags" do
          before do
            td.create_consumer("Consumer")
              .create_provider("Provider")
              .create_consumer_version("1")
              .create_pact
              .create_provider("Another Provider")
              .create_consumer_version("2")
              .create_pact
          end

          context "with both consumer and provider names" do
            let(:pact) { Repository.new.search_for_latest_pact("Consumer", "Provider") }

            it "returns the latest" do
              expect(pact.consumer_version.number).to eq("1")
            end
          end

          context "with only consumer name" do
            let(:pact) { Repository.new.search_for_latest_pact("Consumer", nil) }

            it "returns the latest" do
              expect(pact.consumer_version.number).to eq("2")
            end
          end

          context "with only provider name" do
            let(:pact) { Repository.new.search_for_latest_pact(nil, "Another Provider") }

            it "returns the latest" do
              expect(pact.consumer_version.number).to eq("2")
            end
          end
        end
      end

      describe "find_latest_pacts" do
        before do
          td.create_consumer("Condor")
            .create_consumer_version("1.3.0")
            .create_provider("Pricing Service")
            .create_pact
            .create_consumer_version("1.4.0")
            .create_consumer_version_tag("prod")
            .create_pact
            .create_consumer("Contract Email Service")
            .create_consumer_version("2.6.0")
            .create_provider("Contract Proposal Service")
            .create_pact
            .create_consumer_version("2.7.0")
            .create_pact
            .create_consumer_version("2.8.0") # Create a version without a pact, it shouldn't be used
        end

        it "finds the latest pact for each consumer/provider pair" do
          pacts = Repository.new.find_latest_pacts

          expect(pacts[0].consumer_version.pacticipant.name).to eq("Condor")
          expect(pacts[0].consumer.name).to eq("Condor")
          expect(pacts[0].consumer.id).to_not be nil
          expect(pacts[0].provider.name).to eq("Pricing Service")
          expect(pacts[0].provider.id).to_not be nil
          expect(pacts[0].consumer_version.number).to eq("1.4.0")
          expect(pacts[0].consumer_version.tags.collect(&:name)).to eq ["prod"]

          expect(pacts[1].consumer_version.pacticipant.name).to eq("Contract Email Service")
          expect(pacts[1].consumer.name).to eq("Contract Email Service")
          expect(pacts[1].provider.name).to eq("Contract Proposal Service")
          expect(pacts[1].consumer_version.number).to eq("2.7.0")
          expect(pacts[1].consumer_version.tags.collect(&:name)).to eq []
        end

        it "includes the timestamps - need to update view" do
          pacts = Repository.new.find_latest_pacts
          expect(pacts[0].created_at).to be_datey
        end
      end

      describe "set_latest_main_verification" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_provider_version("2")
        end

        let(:verification) do
          PactBroker::Domain::Verification.new(
            consumer_id: td.consumer.id,
            provider_id: td.provider.id,
            provider_version_id: td.find_version("Bar", "2").id,
            pact_version_id: PactVersion.first.id,
            success: true
          ).save
        end

        subject { Repository.new.set_latest_main_verification(td.and_return(:pact), verification) }

        it "sets the latest main verification" do
          subject
          expect(PactPublication.first.latest_main_verification.id).to eq verification.id
          expect(PactPublication.first.last_verified_at).to_not be nil
        end
      end
    end
  end
end
