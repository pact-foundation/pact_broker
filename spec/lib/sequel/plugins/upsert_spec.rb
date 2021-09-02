require "sequel/plugins/upsert"
require "sequel"

module Sequel
  module Plugins
    module Upsert
      class PacticipantNoUpsert < Sequel::Model(:pacticipants)
        plugin :timestamps, update_on_create: true
      end

      class Pacticipant < Sequel::Model
        plugin :upsert, identifying_columns: [:name]
        plugin :timestamps, update_on_create: true
      end

      class Version < Sequel::Model
        plugin :upsert, identifying_columns: [:pacticipant_id, :number]
        plugin :timestamps, update_on_create: true
      end

      class LatestPactPublicationIdForConsumerVersion < Sequel::Model(:latest_pact_publication_ids_for_consumer_versions)
        set_primary_key [:provider_id, :consumer_version_id]
        unrestrict_primary_key
        plugin :upsert, identifying_columns: [:provider_id, :consumer_version_id]
      end

      describe PacticipantNoUpsert do
        it "has an _insert_dataset method" do
          expect(PacticipantNoUpsert.private_instance_methods).to include(:_insert_dataset)
        end
      end

      describe "LatestPactPublicationIdForConsumerVersion" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version("2")
        end

        let!(:new_pact_publication) do
          pact_publication_values = PactBroker::Pacts::PactPublication.first.values.dup
          pact_publication_values.delete(:id)
          pact_publication_values.delete(:created_at)
          pact_publication_values.delete(:updated_at)
          pact_publication_values[:revision_number] = 2
          PactBroker::Pacts::PactPublication.new(pact_publication_values).save
        end

        let(:new_latest_pact_publication_id_for_consumer_version) do
          values = LatestPactPublicationIdForConsumerVersion.first.values
          LatestPactPublicationIdForConsumerVersion.new(values.merge(pact_publication_id: new_pact_publication.id))
        end

        describe "save" do
          subject { new_latest_pact_publication_id_for_consumer_version.save }

          it "raises an error" do
            expect { subject }.to raise_error Sequel::UniqueConstraintViolation
          end
        end

        describe "upsert" do
          subject { new_latest_pact_publication_id_for_consumer_version.upsert }

          it "updates the new object with the values from the existing object" do
            expect(subject.pact_publication_id).to eq new_pact_publication.id
          end
        end
      end

      context "when a duplicate is inserted with no upsert" do
        before do
          PacticipantNoUpsert.new(name: "Foo").save
        end

        subject do
          PacticipantNoUpsert.new(name: "Foo").save
        end

        it "raises an error" do
          expect { subject }.to raise_error Sequel::UniqueConstraintViolation
        end
      end

      # This doesn't work on MSQL because the _insert_raw method
      # does not return the row ID of the duplicated row when upsert is used
      # May have to go back to the old method of doing this
      context "when a duplicate Pacticipant is inserted with upsert" do
        before do
          Pacticipant.new(name: "Foo", repository_url: "http://foo").upsert
        end

        subject do
          Pacticipant.new(name: "Foo", repository_url: "http://bar").upsert
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end

        it "sets the values on the object" do
          expect(subject.repository_url).to eq "http://bar"
        end

        it "does not insert another row" do
          expect { subject }.to_not change { Pacticipant.count }
        end
      end

      context "when a duplicate Version is inserted with upsert" do
        let!(:pacticipant) { Pacticipant.new(name: "Foo").save }
        let!(:original_version) do
          version = Version.new(
            number: "1",
            pacticipant_id: pacticipant.id,
            build_url: "original-url"
          ).upsert
          Version.where(id: version.id).update(created_at: yesterday, updated_at: yesterday)
          version
        end
        let(:yesterday) { DateTime.now - 2 }

        subject do
          Version.new(number: "1", pacticipant_id: pacticipant.id, build_url: "new-url").upsert
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end

        it "sets the values on the object" do
          expect(subject.build_url).to eq "new-url"
        end

        context "when an attribute is not set" do
          subject do
            Version.new(number: "1", pacticipant_id: pacticipant.id).upsert
          end

          it "nils out values that weren't set on the second model" do
            expect(subject.build_url).to eq nil
          end
        end


        it "does not insert another row" do
          expect { subject }.to_not change { Version.count }
        end

        it "does not change the created_at" do
          expect { subject }.to_not change { Version.where(number: "1").first.created_at }
        end

        it "does change the updated_at" do
          expect { subject }.to change { Version.where(number: "1").first.updated_at }
        end
      end
    end
  end
end
