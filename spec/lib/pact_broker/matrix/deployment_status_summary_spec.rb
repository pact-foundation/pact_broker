require 'pact_broker/matrix/deployment_status_summary'
require 'pact_broker/matrix/row'
require 'pact_broker/matrix/query_results'
require 'pact_broker/matrix/integration'

module PactBroker
  module Matrix
    describe DeploymentStatusSummary do
      describe ".call" do

        let(:rows) { [row_1, row_2] }
        let(:row_1) do
          double(Row,
            consumer_name: "Foo",
            consumer_id: 1,
            provider_name: "Bar",
            provider_id: 2,
            success: row_1_success
          )
        end

        let(:row_2) do
          double(Row,
            consumer_name: "Foo",
            consumer_id: 1,
            provider_name: "Baz",
            provider_id: 3,
            success: true
          )
        end

        let(:row_1_success) { true }

        let(:integrations) do
          [
            Integration.new(1, "Foo", 2, "Bar"),
            Integration.new(1, "Foo", 3, "Baz")
          ]
        end

        let(:resolved_selectors) do
          [
            {
              pacticipant_id: 1, pacticipant_version_number: "ddec8101dabf4edf9125a69f9a161f0f294af43c"
            },
            {
              pacticipant_id: 2, pacticipant_version_number: "14131c5da3abf323ccf410b1b619edac76231243"
            },
            {
              pacticipant_id: 3, pacticipant_version_number: "4ee06460f10e8207ad904fa9fa6c4842e462ab59"
            }
          ]
        end


        subject { DeploymentStatusSummary.new(rows, resolved_selectors, integrations) }

        context "when there is a row for all integrations" do
          its(:deployable?) { is_expected.to be true }
          its(:reasons) { is_expected.to eq ["All verification results are published and successful"] }
          its(:counts) { is_expected.to eq success: 2, failed: 0, unknown: 0 }
        end

        context "when there are no rows" do
          let(:rows) { [] }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq ["No results matched the given query"] }
          its(:counts) { is_expected.to eq success: 0, failed: 0, unknown: 2 }
        end

        context "when one or more of the success flags are nil" do
          let(:row_1_success) { nil }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq ["Missing one or more verification results"] }
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 1 }
        end

        context "when one or more of the success flags are false" do
          let(:row_1_success) { false }

          its(:deployable?) { is_expected.to be false }
          its(:reasons) { is_expected.to eq ["One or more verifications have failed"] }
          its(:counts) { is_expected.to eq success: 1, failed: 1, unknown: 0 }
        end

        context "when there is a relationship missing" do
          let(:rows) { [row_1] }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq ["There is no verified pact between Foo (ddec8101dabf4edf9125a69f9a161f0f294af43c) and Baz (4ee06460f10e8207ad904fa9fa6c4842e462ab59)"] }
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 1 }
        end
      end
    end
  end
end
