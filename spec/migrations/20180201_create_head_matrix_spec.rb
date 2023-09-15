describe "latest tagged matrix", migration: true do
  before do
    PactBroker::TestDatabase.migrate
  end

  subject { database[:head_matrix].all }

  context "with a single consumer version tag on the latest version" do
    before do
      td.create_pact_with_hierarchy("Foo", "1", "Bar")
        .create_consumer_version_tag("prod")
        .create_consumer_version("2")
        .create_consumer_version_tag("prod")
        .create_pact
        .revise_pact
    end

    context "without a verification" do
      it "returns a line with no tag and a line with a tag" do
        expect(subject).to contain_hash(
          consumer_version_tag_name: nil,
          consumer_version_number: "2"
        )
        expect(subject).to contain_hash(
          consumer_version_tag_name: "prod",
          consumer_version_number: "2"
        )
      end
    end

    context "with a verification" do
      before do
        td.create_verification(provider_version: "3")
      end
      it "returns the verification details" do
        expect(subject).to contain_hash(
          consumer_version_tag_name: nil,
          consumer_version_number: "2",
          provider_version_number: "3"
        )
        expect(subject).to contain_hash(
          consumer_version_tag_name: "prod",
          consumer_version_number: "2",
          provider_version_number: "3"
        )
      end
    end
  end
  context "with two tags on the latest version" do
    before do
      td.create_pact_with_hierarchy("Foo", "1", "Bar")
        .create_consumer_version_tag("prod")
        .create_consumer_version_tag("master")
        .create_consumer_version("2")
        .create_consumer_version_tag("prod")
        .create_consumer_version_tag("master")
        .create_pact
        .revise_pact
    end

    it "returns a line with no tag, and a line for each tag" do
      expect(subject).to contain_hash(
        consumer_version_tag_name: nil,
        consumer_version_number: "2"
      )
      expect(subject).to contain_hash(
        consumer_version_tag_name: "prod",
        consumer_version_number: "2"
      )

      expect(subject).to contain_hash(
        consumer_version_tag_name: "master",
        consumer_version_number: "2"
      )
    end

    context "with a verification" do
      before do
        td.create_verification(provider_version: "3")
      end
      it "returns the verification details" do
        expect(subject).to contain_hash(
          consumer_version_tag_name: nil,
          consumer_version_number: "2",
          provider_version_number: "3"
        )
        expect(subject).to contain_hash(
          consumer_version_tag_name: "prod",
          consumer_version_number: "2",
          provider_version_number: "3"
        )

        expect(subject).to contain_hash(
          consumer_version_tag_name: "master",
          consumer_version_number: "2",
          provider_version_number: "3"
        )
      end
    end
  end
  context "with different versions for overall latest, and two other tags" do
    before do
      td.create_pact_with_hierarchy("Foo", "1", "Bar")
        .create_consumer_version_tag("prod")
        .create_consumer_version_tag("master")
        .create_consumer_version("2")
        .create_consumer_version_tag("master")
        .create_pact
        .revise_pact
        .create_consumer_version("3")
        .create_pact
    end

    it "returns a line for each" do
      expect(subject).to contain_hash(
        consumer_version_tag_name: nil,
        consumer_version_number: "3"
      )
      expect(subject).to contain_hash(
        consumer_version_tag_name: "prod",
        consumer_version_number: "1"
      )

      expect(subject).to contain_hash(
        consumer_version_tag_name: "master",
        consumer_version_number: "2"
      )
    end
  end
end
