require 'pact_broker/matrix/aggregated_row'

module PactBroker
  module Matrix
    describe AggregatedRow do
      describe "latest_verification_for_pseudo_branch" do
        let(:row_1) do
          instance_double('PactBroker::Matrix::HeadRow',
            consumer_name: "Foo",
            provider_name: "Bar",
            verification: verification_1,
            latest_verification_for_consumer_version_tag: tag_verification_1,
            consumer_version_tag_name: consumer_version_tag_name_1)
        end
        let(:row_2) do
          instance_double('PactBroker::Matrix::HeadRow',
            verification: verification_2,
            latest_verification_for_consumer_version_tag: tag_verification_2,
            consumer_version_tag_name: consumer_version_tag_name_2)
        end
        let(:verification_1) { instance_double('PactBroker::Domain::Verification', id: 1) }
        let(:verification_2) { instance_double('PactBroker::Domain::Verification', id: 2) }
        let(:tag_verification_1) { instance_double('PactBroker::Domain::Verification', id: 3) }
        let(:tag_verification_2) { instance_double('PactBroker::Domain::Verification', id: 4) }
        let(:consumer_version_tag_name_1) { 'master' }
        let(:consumer_version_tag_name_2) { 'prod' }
        let(:rows) { [row_1, row_2] }
        let(:aggregated_row) { AggregatedRow.new(rows) }

        subject { aggregated_row.latest_verification_for_pseudo_branch }

        context "when the rows have verifications" do
          it "returns the verification with the largest id" do
            expect(subject).to be verification_2
          end
        end

        context "when the rows do not have verifications, but there are a previous verifications for a pacts with the same tag" do
          let(:verification_1) { nil }
          let(:verification_2) { nil }

          it "returns the verification for the previous pact that has the largest id" do
            expect(subject).to be tag_verification_2
          end
        end

        context "when there is no verification for any of the rows or any of the pacts with the same tag" do
          let(:verification_1) { nil }
          let(:verification_2) { nil }
          let(:tag_verification_1) { nil }
          let(:tag_verification_2) { nil }

          context "when one of the rows is the overall latest" do
            let(:consumer_version_tag_name_1) { nil }
            let(:overall_latest_verification) { instance_double('PactBroker::Domain::Verification', id: 1) }
            before do
              allow(row_1).to receive(:latest_verification_for_consumer_and_provider).and_return(overall_latest_verification)
            end

            it "looks up the overall latest verification" do
              expect(row_1).to receive(:latest_verification_for_consumer_and_provider)
              subject
            end

            it "returns the overall latest verification" do
              expect(subject).to be overall_latest_verification
            end
          end

          context "when none of the rows is not the overall latest (they are all the latest with a tag)" do
            it "returns nil" do
              expect(subject).to be nil
            end
          end
        end
      end
    end
  end
end
