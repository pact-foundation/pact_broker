require 'pact_broker/pacts/pact_publication'

module PactBroker
  module Pacts
    describe PactPublication do

      describe "#latest_tag_names" do
        before do
          td.create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
            .create_consumer_version_tag("no")
            .create_consumer_version("3.4.5")
            .create_consumer_version_tag("yes")
            .create_pact
            .create_consumer_version("5.6.7")
            .create_consumer_version_tag("no")
        end

        let(:td) { TestDataBuilder.new }
        let(:pact_publication) { PactPublication.find(id: td.pact.id) }

        context "when the pact is the latest for a tag" do
          it "returns the relevant tag names" do
            expect(pact_publication.latest_tag_names).to eq ["yes"]
          end
        end

        context "when the pact is not the latest for a tag" do
          it "returns the relevant tag names" do
            expect(pact_publication.latest_tag_names).to eq ["yes"]
          end
        end
      end
    end
  end
end
