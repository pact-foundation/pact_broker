require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    describe Row do
      let(:td) { TestDataBuilder.new }

      describe "latest_verification_for_consumer_and_provider" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "9")
            .create_consumer_version("2")
            .create_consumer_version_tag("prod")
            .create_pact
            .create_verification(provider_version: "10")
            .create_consumer("Wiffle")
            .create_consumer_version("4")
            .create_pact
            .create_verification(provider_version: "11")
        end

        subject { Row.where(consumer_name: "Foo", provider_name: "Bar").all.collect(&:latest_verification_for_consumer_and_provider) }

        it "returns the latest verification for the consumer and provider" do
          expect(subject.collect(&:provider_version_number)).to eq ["10", "10"]
        end
      end

      describe "<=>" do
        let(:row_1) do
          Row.new(
            consumer_name: 'A',
            consumer_version_order: 1,
            pact_revision_number: 1,
            provider_name: 'B',
            provider_version_order: 1,
            verification_id: 1
          )
        end
        let(:row_2) do
          Row.new(
            consumer_name: 'A',
            consumer_version_order: 1,
            pact_revision_number: 1,
            provider_name: 'B',
            provider_version_order: 1,
            verification_id: 2
          )
        end

        it "sorts" do
          expect([row_1, row_2].sort).to eq [row_2, row_1]
        end

        context "with a nil column" do
          let(:row_2) do
            Row.new(
              consumer_name: 'A',
              consumer_version_order: 1,
              pact_revision_number: 1,
              provider_name: 'B',
              provider_version_order: nil,
              verification_id: nil
            )
          end

          it "sorts the rows first" do
            expect([row_1, row_2].sort).to eq [row_2, row_1]
          end
        end
      end
    end
  end
end
