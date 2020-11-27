require 'pact_broker/pacts/pact_publication'

module PactBroker
  module Pacts
    describe PactPublication do
      describe "to_domain" do
        before do
          td.create_pact_with_verification("Foo", "1", "Bar", "2")
        end

        subject { PactPublication.first.to_domain }

        its(:latest_verification) { is_expected.to_not be nil }
      end

      describe "to_domain_lightweight" do
        before do
          td.create_pact_with_verification("Foo", "1", "Bar", "2")
        end

        subject { PactPublication.first.to_domain_lightweight }

        it "raises an error if you try to access the latest_verification" do
          expect { subject.latest_verification }.to raise_error PactBroker::UnsetAttributeError
        end
      end

      describe "save and upsert" do
        before do
          td.create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
        end

        let(:params) do
          {
            consumer_id: td.consumer.id,
            provider_id: td.provider.id,
            consumer_version_id: td.consumer_version.id,
            pact_version_id: PactVersion.first.id,
            revision_number: 1
          }
        end

        let(:pact_publication) do
          PactPublication.new(params)
        end

        context "when using a PactPublication with the same provider/consumer version/revision number as an existing PactPublication" do
          describe "save" do
            it "raises a constraint exception" do
              expect { pact_publication.save }.to raise_error Sequel::UniqueConstraintViolation
            end
          end

          describe "upsert" do
            it "does not raise an error" do
              pact_publication.upsert
            end

            it "sets the relationship objects" do
              pact_publication.upsert
              expect(pact_publication.id).to_not be nil
              expect(pact_publication.consumer.id).to eq td.consumer.id
              expect(pact_publication.consumer.name).to eq td.consumer.name
            end

            context "with objects instead of ids" do
              let(:params) do
                {
                  consumer: td.consumer,
                  provider: td.provider,
                  consumer_version: td.consumer_version,
                  pact_version: PactVersion.first,
                  revision_number: 1
                }
              end

              it "also works" do
                pact_publication.upsert
                expect(pact_publication.consumer_id).to eq td.consumer.id
              end
            end
          end
        end
      end

      describe "#consumer_version_tags" do
        before do
          td.create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
            .create_consumer_version_tag("no")
            .create_consumer_version("3.4.5")
            .create_consumer_version_tag("yes")
            .create_pact
            .create_consumer_version("5.6.7")
            .create_consumer_version_tag("no")
        end

        let(:pact_publication) { PactPublication.find(id: td.pact.id) }

        it "" do
          expect(pact_publication.consumer_version_tags.collect(&:name)).to eq ["yes"]
        end
      end

      describe "#head_tag_names" do
        before do
          td.create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
            .create_consumer_version_tag("no")
            .create_consumer_version("3.4.5")
            .create_consumer_version_tag("yes")
            .create_pact
            .create_consumer_version("5.6.7")
            .create_consumer_version_tag("no")
            .create_consumer("Foo2")
            .create_consumer_version("3.4.5")
            .create_consumer_version_tag("yes", comment: "actually no, just here to make sure it selects the right one")
        end

        let(:pact_publication) { PactPublication.find(id: td.pact.id) }

        context "when the pact is the latest for a tag" do
          it "returns the relevant tag names" do
            expect(pact_publication.head_tag_names).to eq ["yes"]
            expect(pact_publication.head_pact_tags.collect(&:name)).to eq ["yes"]
          end
        end

        context "when the pact is not the latest for a tag" do
          it "returns the relevant tag names" do
            expect(pact_publication.head_tag_names).to eq ["yes"]
            expect(pact_publication.head_pact_tags.collect(&:name)).to eq ["yes"]
          end
        end
      end
    end
  end
end
