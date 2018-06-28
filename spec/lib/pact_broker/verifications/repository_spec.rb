require 'pact_broker/verifications/repository'

module PactBroker
  module Verifications
    describe Repository do
      describe "#find" do
        let!(:pact) do
          builder = TestDataBuilder.new
          pact = builder
            .create_provider("Provider1")
            .create_consumer("Consumer1")
            .create_consumer_version("1.0.0")
            .create_pact
            .and_return(:pact)

          builder
            .create_verification(number: 1)
            .create_verification(number: 2, provider_version: '3.7.4')
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1)

            TestDataBuilder.new
            .create_provider("Provider3")
            .create_consumer("Consumer2")
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1)
          pact
        end

        subject { Repository.new.find "Consumer1", "Provider1", pact.pact_version_sha, 2}

        it "finds the latest verifications for the given consumer version" do
          expect(subject.provider_version_number).to eq "3.7.4"
          expect(subject.consumer_name).to eq "Consumer1"
          expect(subject.provider_name).to eq "Provider1"
          expect(subject.pact_version_sha).to eq pact.pact_version_sha
        end
      end

      describe "#find_latest_verifications_for_consumer_version" do
        before do
          TestDataBuilder.new
            .create_provider("Provider1")
            .create_consumer("Consumer1")
            .create_consumer_version("1.0.0")
            .create_pact
            .create_verification(number: 1)
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1)
            .create_verification(number: 2, provider_version: "7.8.9")
            .create_provider("Provider2")
            .create_pact
            .create_verification(number: 1, provider_version: "6.5.4")

            TestDataBuilder.new
            .create_provider("Provider3")
            .create_consumer("Consumer2")
            .create_consumer_version("1.2.3")
            .create_pact
            .create_verification(number: 1)
        end

        subject { Repository.new.find_latest_verifications_for_consumer_version("Consumer1", "1.2.3")}

        it "finds the latest verifications for the given consumer version" do
          expect(subject.first.provider_version_number).to eq "7.8.9"
          expect(subject.last.provider_version_number).to eq "6.5.4"
        end
      end

      describe "#search_for_latest" do
        before do
          TestDataBuilder.new
            .create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "2")
            .create_verification(provider_version: "3", number: 2)
            .create_provider("Wiffle")
            .create_pact
            .create_verification(provider_version: "4")
        end

        context "with just the consumer name" do
          subject { Repository.new.search_for_latest("Foo", nil) }

          its(:provider_version_number) { is_expected.to eq "4" }
        end

        context "with the consumer and provider name" do
          subject { Repository.new.search_for_latest("Foo", "Bar") }

          its(:provider_version_number) { is_expected.to eq "3" }
        end

        context "with just the provider name" do
          subject { Repository.new.search_for_latest(nil, "Bar") }

          its(:provider_version_number) { is_expected.to eq "3" }
        end

        context "with neither name" do
          subject { Repository.new.search_for_latest(nil, nil) }

          its(:provider_version_number) { is_expected.to eq "4" }
        end
      end

      describe "#find_latest_verification_for" do
        context "when there is a revision" do
          before do
            TestDataBuilder.new
              .create_provider("Provider1")
              .create_consumer("Consumer1")
              .create_consumer_version("1.2.3")
              .create_pact
              .create_verification(number: 1, provider_version: "2.3.4")
              .revise_pact
              .create_verification(number: 1, provider_version: "7.8.9")
          end

          subject { Repository.new.find_latest_verification_for("Consumer1", "Provider1")}

          it "finds the latest verifications for the given consumer version" do
            expect(subject.provider_version_number).to eq "7.8.9"
          end
        end

        context "when no tag is specified" do
          before do
            PactBroker.configuration.order_versions_by_date = false
            TestDataBuilder.new
              .create_provider("Provider1")
              .create_consumer("Consumer1")
              .create_consumer_version("1.2.3")
              .create_pact
              .create_verification(number: 1, provider_version: "2.3.4")
              .create_verification(number: 2, provider_version: "7.8.9")
              .create_consumer_version("1.0.0")
              .create_pact
              .create_verification(number: 1, provider_version: "5.4.3")
              .create_provider("Provider2")
              .create_pact
              .create_verification(number: 1, provider_version: "6.5.4")
              .create_consumer_version("2.0.0")
              .create_pact
          end

          subject { Repository.new.find_latest_verification_for("Consumer1", "Provider1")}

          it "finds the latest verifications for the given consumer version" do
            expect(subject.provider_version_number).to eq "7.8.9"
          end
        end

        context "when a tag is specified" do
          before do
            TestDataBuilder.new
              .create_provider("Provider1")
              .create_consumer("Consumer1")
              .create_consumer_version("1.0.0")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(number: 1, provider_version: "1.0.0")
              .create_verification(number: 2, provider_version: "5.4.3")
              .create_consumer_version("1.1.0")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_consumer_version("1.2.3")
              .create_pact
              .create_verification(number: 1, provider_version: "2.3.4")
              .create_verification(number: 2, provider_version: "7.8.9")
              .create_provider("Provider2")
              .create_pact
              .create_verification(number: 1, provider_version: "6.5.4")
              .create_consumer_version("2.0.0")
              .create_pact
          end

          subject { Repository.new.find_latest_verification_for("Consumer1", "Provider1", 'prod')}

          it "finds the latest verifications for the given consumer version with the specified tag" do
            expect(subject.provider_version_number).to eq "5.4.3"
          end

          context "when no verification exists" do
            subject { Repository.new.find_latest_verification_for("Consumer1", "Provider1", 'foo')}

            it "returns nil" do
              expect(subject).to be nil
            end
          end
        end

        context "when the latest untagged verification is required" do
          before do
            TestDataBuilder.new
              .create_provider("Provider1")
              .create_consumer("Consumer1")
              .create_consumer_version("1.0.0")
              .create_pact
              .create_verification(number: 1, provider_version: "1.0.0")
              .create_verification(number: 2, provider_version: "5.4.3")
              .create_consumer_version("1.1.0")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_consumer_version("1.2.3")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(number: 1, provider_version: "2.3.4")
              .create_verification(number: 2, provider_version: "7.8.9")
              .create_provider("Provider2")
              .create_pact
              .create_verification(number: 1, provider_version: "6.5.4")
              .create_consumer_version("2.0.0")
              .create_pact
          end

          subject { Repository.new.find_latest_verification_for("Consumer1", "Provider1", :untagged)}

          it "finds the latest verifications for the given consumer version with no tag" do
            expect(subject.provider_version_number).to eq "5.4.3"
          end
        end
      end

      describe "find_latest_verification_for_tags" do
        context "with no revisions" do
          before do
            TestDataBuilder.new
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("feat-x")
              .create_verification(provider_version: "5")
              .use_provider_version("5")
              .create_provider_version_tag("feat-y")
              .create_verification(provider_version: "6", number: 2)
              .use_provider_version("6")
              .create_provider_version_tag("feat-y")
              .create_verification(provider_version: "7", number: 3)
              .create_consumer_version("2")
              .create_pact
              .create_verification(provider_version: "8")
          end

          subject { Repository.new.find_latest_verification_for_tags("Foo", "Bar", "feat-x", "feat-y") }

          it "returns the latest verification for a pact with the given consumer tag, by a provider version with the given provider tag" do
            expect(subject.provider_version_number).to eq "6"
          end
        end

        context "when a verification exists for a pact revision that was then overwritten by a new revision of the pact" do
          let(:content_1) { { content: 1 }.to_json }
          let(:content_2) { { content: 2 }.to_json }

          before do
            TestDataBuilder.new
              .create_pact_with_hierarchy("Foo", "1", "Bar", content_1)
              .create_consumer_version_tag("develop")
              .create_verification(provider_version: "5", number: 1, tag_name: "develop", comment: "not this because pact revised")
              .create_verification(provider_version: "6", number: 2, tag_name: "develop", comment: "not this because pact revised")
              .revise_pact(content_2)
              .create_verification(provider_version: "1", number: 1, tag_name: "develop", comment: "not this because later one exists")
              .create_verification(provider_version: "2", number: 2, tag_name: "develop", comment: "this one!")
              .create_consumer_version("2")
              .create_pact(json_content: content_1)
          end

          subject { Repository.new.find_latest_verification_for_tags("Foo", "Bar", "develop", "develop") }

          it "returns the latest verification " do
            expect(subject.provider_version_number).to eq "2"
            expect(subject.number).to eq 2
          end
        end
      end

      describe "delete_by_provider_version_id" do
        let!(:provider_version) do
          TestDataBuilder.new
            .create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_verification(provider_version: "1.0.0")
            .create_verification(provider_version: "2.0.0", number: 2)
            .create_verification(provider_version: "2.0.0", number: 3)
            .and_return(:provider_version)
        end

        subject { Repository.new.delete_by_provider_version_id(provider_version.id) }

        it "deletes the verifications associated with the given version id" do
          expect { subject }.to change { PactBroker::Domain::Verification.count }.by(-2)
        end
      end
    end
  end
end
