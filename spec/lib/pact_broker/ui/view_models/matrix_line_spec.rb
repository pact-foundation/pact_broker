require "pact_broker/matrix/quick_row"
require "pact_broker/ui/view_models/matrix_line"

module PactBroker
  module UI
    module ViewDomain
      describe MatrixLine do
        let(:line) { instance_spy(PactBroker::Matrix::QuickRow) }

        subject(:matrix_line) { described_class.new(line) }

        describe "#provide_version_order" do
          subject(:provider_version_order) { matrix_line.provider_version_order }

          context "verification execution time exists" do
            let(:verification_executed_at) { Time.now }

            before do
              allow(line).to receive(:verification_executed_at)
                .and_return(verification_executed_at)
            end

            it "returns verification execution timestamp" do
              timestamp = verification_executed_at.to_i

              expect(provider_version_order).to eq(timestamp)
            end
          end

          context "verification execution time does not exist" do
            before do
              allow(line).to receive(:verification_executed_at).and_return(nil)
            end

            it { is_expected.to eq(0) }
          end
        end
      end
    end
  end
end
