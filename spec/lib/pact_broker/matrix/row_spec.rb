require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    describe Row do
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
