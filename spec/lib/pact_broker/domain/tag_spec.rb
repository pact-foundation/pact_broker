require "pact_broker/domain/tag"

module PactBroker
  module Domain
    describe Tag do
      describe "#latest_tags_for_pacticipant_ids_and_tag_names" do
        before do
          td.create_consumer("bar")
            .create_consumer_version("1", tag_names: ["dev", "prod"])
            .create_consumer("foo")
            .create_consumer_version("1", tag_names: ["dev", "prod"])
            .create_consumer_version("2", tag_names: ["dev"])
            .create_consumer_version("3")
        end

        let(:foo) { td.find_pacticipant("foo") }
        let(:foo_version_1) { td.find_version("foo", "1") }
        let(:foo_version_2) { td.find_version("foo", "2") }

        subject { Tag.latest_tags_for_pacticipant_ids_and_tag_names([foo.id], ["dev", "prod"]).order(:name).all }

        it "returns the latest tag grouped by pacticipant id and tag name" do
          expect(subject.size).to eq 2
          expect(subject.first).to have_attributes(version_id: foo_version_2.id, pacticipant_id: foo.id)
          expect(subject.last).to have_attributes(version_id: foo_version_1.id, pacticipant_id: foo.id)
        end
      end

      describe "#latest_tags_for_pacticipant_ids" do
        before do
          td.create_consumer("foo")
            .create_consumer_version("1")
            .create_consumer_version_tag("dev")
            .create_consumer_version_tag("prod")
            .create_consumer_version("2")
            .create_consumer_version_tag("dev")
            .create_consumer_version_tag("bloop")
            .create_consumer_version("3")
            .create_consumer_version_tag("dev")
            .create_consumer("bar")
            .create_consumer_version("1")
            .create_consumer_version_tag("test")
        end

        it "returns the latest tags for the given pacticipant ids" do
          pacticipant = PactBroker::Domain::Pacticipant.order(:id).first
          tags = Tag.latest_tags_for_pacticipant_ids([pacticipant.id]).all
          expect(tags.collect(&:name).sort).to eq %w{bloop dev prod}
          expect(tags.find{ |t| t.name == "dev" }.version.number).to eq "3"
          expect(tags.find{ |t| t.name == "prod" }.version.number).to eq "1"
          expect(tags.find{ |t| t.name == "bloop" }.version.number).to eq "2"
          expect(tags.collect(&:version_id).compact.size).to eq 3
          expect(tags.collect(&:created_at).compact.size).to eq 3
        end
      end

      describe "latest_tags" do
        before do
          td.create_consumer("foo")
            .create_consumer_version("1")
            .create_consumer_version_tag("dev")
            .create_consumer_version_tag("prod")
            .create_consumer_version("2")
            .create_consumer_version_tag("dev")
            .create_consumer_version_tag("bloop")
            .create_consumer_version("3")
            .create_consumer_version_tag("dev")
            .create_consumer("bar")
            .create_consumer_version("1")
            .create_consumer_version_tag("test")
        end

        it "returns the tags that belong to the most recent version with that tag/pacticipant" do
          tags = Tag.latest_tags.all
          expect(tags.collect(&:name).sort).to eq %w{bloop dev prod test}
          expect(tags.find{ |t| t.name == "dev" }.version.number).to eq "3"
          expect(tags.find{ |t| t.name == "prod" }.version.number).to eq "1"
          expect(tags.find{ |t| t.name == "bloop" }.version.number).to eq "2"
          expect(tags.collect(&:version_id).compact.size).to eq 4
          expect(tags.collect(&:created_at).compact.size).to eq 4
        end
      end

      describe "latest_for_pacticipant?" do
        before do
          # Foo v1 Bar1
          # Foo v1 Bar2
          # Foo v2 Bar1
          td.create_pact_with_verification_and_tags("Foo", "1", ["dev", "prod"], "Bar1")
            .create_provider("Bar2")
            .create_pact
            .create_pact_with_verification_and_tags("Foo", "2", ["dev"], "Bar1")
            .create_consumer_version("3")
            .create_consumer_version_tag("dev")
        end

        it "returns true if there are no other tags with that name for that pacticipant for a later version" do
          version_1 = PactBroker::Versions::Repository.new.find_by_pacticipant_name_and_number("Foo", "1")
          expect(version_1.tags.find { |t| t.name == "prod" }.latest_for_pacticipant?).to be true
          expect(version_1.tags.find { |t| t.name == "dev" }.latest_for_pacticipant?).to be false
        end
      end

      describe "head_tags_for_pact_publication" do
        before do
          # Foo v1 Bar1
          # Foo v1 Bar2
          # Foo v2 Bar1
          td.create_pact_with_verification_and_tags("Foo", "1", ["dev", "prod"], "Bar1")
            .create_provider("Bar2")
            .create_pact
            .create_pact_with_verification_and_tags("Foo", "2", ["dev"], "Bar1")
            .create_consumer_version("3")
            .create_consumer_version_tag("dev")
        end

        it "returns the names of the tags for which this pact publication is the latest" do
          pact_0 = PactBroker::Pacts::PactPublication.find(id: PactBroker::Pacts::Repository.new.find_pact("Foo", "1", "Bar1").id)
          expect(pact_0.consumer_version.tags.collect(&:name).sort).to eq ["dev", "prod"]
          expect(Tag.head_tags_for_pact_publication(pact_0).collect(&:name).sort).to eq ["prod"]

          pact_1 = PactBroker::Pacts::PactPublication.find(id: PactBroker::Pacts::Repository.new.find_pact("Foo", "2", "Bar1").id)
          expect(Tag.head_tags_for_pact_publication(pact_1).collect(&:name).sort).to eq ["dev"]

          pact_2 = PactBroker::Pacts::PactPublication.find(id: PactBroker::Pacts::Repository.new.find_pact("Foo", "1", "Bar2").id)
          expect(Tag.head_tags_for_pact_publication(pact_2).collect(&:name).sort).to eq ["dev", "prod"]
        end
      end

      describe "head_tag" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("1", tag_names: ["main", "test"])
            .create_consumer_version("2", tag_names: ["main", "test"])
            .create_consumer_version("3", tag_names: ["main"])
            .create_provider("Bar")
            .create_provider_version("1", tag_names: ["main", "test"])
            .create_provider_version("2", tag_names: ["main", "test"])
            .create_provider_version("3", tag_names: ["main"])
        end

        it "lazy loads" do
          expect(Tag.for("Foo", "2", "main").head_tag).to eq Tag.for("Foo", "3", "main")
          expect(Tag.for("Foo", "3", "main").head_tag).to eq Tag.for("Foo", "3", "main")
          expect(Tag.for("Bar", "1", "test").head_tag).to eq Tag.for("Bar", "2", "test")
        end

        it "eager loads" do
          tags = Tag.order(:version_order, :name).eager(:head_tag).all
          expect(tags[0].head_tag).to eq Tag.for("Foo", "3", "main")
          expect(tags[1].head_tag).to eq Tag.for("Foo", "2", "test")
        end
      end
    end
  end
end
