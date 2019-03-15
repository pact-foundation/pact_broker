require 'pact_broker/matrix/deployment_status_summary'
require 'pact_broker/matrix/row'
require 'pact_broker/matrix/query_results'
require 'pact_broker/matrix/integration'
require 'pact_broker/matrix/resolved_selector'

module PactBroker
  module Matrix
    describe DeploymentStatusSummary do

      before do
        allow(subject).to receive(:logger).and_return(logger)
      end

      let(:logger) { double('logger').as_null_object }

      describe ".call" do
        let(:rows) { [row_1, row_2] }
        let(:row_1) do
          double(Row,
            consumer_name: "Foo",
            consumer_id: 1,
            provider_name: "Bar",
            provider_id: 2,
            success: row_1_success,
            pacticipant_names: %w{Foo Bar}
          )
        end

        let(:row_2) do
          double(Row,
            consumer_name: "Foo",
            consumer_id: 1,
            provider_name: "Baz",
            provider_id: 3,
            success: true,
            pacticipant_names: %w{Foo Baz}
          )
        end

        let(:row_1_success) { true }

        let(:integrations) do
          [
            Integration.new(1, "Foo", 2, "Bar", true),
            Integration.new(1, "Foo", 3, "Baz", true)
          ]
        end

        let(:foo) { double('foo', id: 1, name: "Foo") }
        let(:bar) { double('bar', id: 2, name: "Bar") }
        let(:baz) { double('baz', id: 3, name: "Baz") }
        let(:foo_version) { double('foo version', number: "ddec8101dabf4edf9125a69f9a161f0f294af43c", id: 10)}
        let(:bar_version) { double('bar version', number: "14131c5da3abf323ccf410b1b619edac76231243", id: 10)}
        let(:baz_version) { double('baz version', number: "4ee06460f10e8207ad904fa9fa6c4842e462ab59", id: 10)}

        let(:resolved_selectors) do
          [
            double('foo selector',
              pacticipant_id: 1,
              pacticipant_name: "Foo",
              pacticipant_version_number: "ddec8101dabf4edf9125a69f9a161f0f294af43c",
              pacticipant_version_id: 10,
              latest_tagged_version_that_does_not_exist?: false,
              specified_version_that_does_not_exist?: false,
              description: "version ddec8101dabf4edf9125a69f9a161f0f294af43c of Foo"
            ),
            double('bar selector',
              pacticipant_id: 2,
              pacticipant_name: "Bar",
              pacticipant_version_number: "14131c5da3abf323ccf410b1b619edac76231243",
              pacticipant_version_id: 11,
              latest_tagged_version_that_does_not_exist?: false,
              specified_version_that_does_not_exist?: false,
              description: "version 14131c5da3abf323ccf410b1b619edac76231243 of Bar"
            ),
            double('baz selector',
             pacticipant_id: 3,
             pacticipant_name: "Baz",
             pacticipant_version_number: "4ee06460f10e8207ad904fa9fa6c4842e462ab59",
             pacticipant_version_id: 12,
             latest_tagged_version_that_does_not_exist?: false,
             specified_version_that_does_not_exist?: false,
             description: "version 4ee06460f10e8207ad904fa9fa6c4842e462ab59 of Baz"
            ),
          ]
        end

        subject { DeploymentStatusSummary.new(rows, resolved_selectors, integrations) }

        context "when there is a row for all integrations" do
          its(:deployable?) { is_expected.to be true }
          its(:reasons) { is_expected.to eq ["All required verification results are published and successful"] }
          its(:counts) { is_expected.to eq success: 2, failed: 0, unknown: 0 }
        end

        context "when there are no rows" do
          let(:rows) { [] }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) do
            is_expected.to eq [
              "There is no verified pact between version ddec8101dabf4edf9125a69f9a161f0f294af43c of Foo and version 14131c5da3abf323ccf410b1b619edac76231243 of Bar",
              "There is no verified pact between version ddec8101dabf4edf9125a69f9a161f0f294af43c of Foo and version 4ee06460f10e8207ad904fa9fa6c4842e462ab59 of Baz",
            ]
          end
          its(:counts) { is_expected.to eq success: 0, failed: 0, unknown: 2 }
        end

        context "when one or more of the success flags are nil" do
          let(:row_1_success) { nil }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) do
            is_expected.to eq [
              "There is no verified pact between version ddec8101dabf4edf9125a69f9a161f0f294af43c of Foo and version 14131c5da3abf323ccf410b1b619edac76231243 of Bar",
              "There is no verified pact between version ddec8101dabf4edf9125a69f9a161f0f294af43c of Foo and version 4ee06460f10e8207ad904fa9fa6c4842e462ab59 of Baz",
            ]
          end
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 1 }
        end

        context "when one or more of the success flags are false" do
          let(:row_1_success) { false }

          its(:deployable?) { is_expected.to be false }
          its(:reasons) { is_expected.to eq ["One or more verifications have failed"] }
          its(:counts) { is_expected.to eq success: 1, failed: 1, unknown: 0 }
        end

        context "when there is a provider relationship missing" do
          let(:rows) { [row_1] }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq ["There is no verified pact between version ddec8101dabf4edf9125a69f9a161f0f294af43c of Foo and version 4ee06460f10e8207ad904fa9fa6c4842e462ab59 of Baz"] }
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 1 }
        end

        context "when there is a consumer integration missing and only the provider was specified in the query" do
          let(:rows) { [row_1] }
          let(:integrations) do
            [
              Integration.new(1, "Foo", 2, "Bar", true),
              Integration.new(3, "Baz", 2, "Bar", false) # the missing one
            ]
          end

          its(:deployable?) { is_expected.to be true }
          its(:reasons) { is_expected.to eq ["All required verification results are published and successful"] }
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 0 }
        end

        context "when there is a provider integration missing and only the consumer was specified in the query" do
          let(:rows) { [row_1] }

          let(:integrations) do
            [
              Integration.new(1, "Foo", 2, "Bar", true),
              Integration.new(1, "Foo", 3, "Baz", true) # the missing one
            ]
          end

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq ["There is no verified pact between version ddec8101dabf4edf9125a69f9a161f0f294af43c of Foo and version 4ee06460f10e8207ad904fa9fa6c4842e462ab59 of Baz"] }
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 1 }
        end

        context "when there is a provider integration missing because the provider version does not exist" do
          let(:rows) { [] }
          let(:integrations) do
            [
              Integration.new(1, "Foo", 2, "Bar", true)
            ]
          end

          let(:resolved_selectors) do
            [
              double('foo selector',
                pacticipant_id: 1,
                pacticipant_name: "Foo",
                pacticipant_version_number: "ddec8101dabf4edf9125a69f9a161f0f294af43c",
                pacticipant_version_id: 10,
                latest_tagged_version_that_does_not_exist?: false,
                specified_version_that_does_not_exist?: false,
                description: 'verison foo'),
              double('bar selector',
               pacticipant_id: 2,
               pacticipant_name: "Bar",
               pacticipant_version_number: "",
               pacticipant_version_id: 11,
               latest_tagged_version_that_does_not_exist?: true,
               involves_pacticipant_with_name?: true,
               version_does_not_exist_description: "description",
               specified_version_that_does_not_exist?: false,
               description: 'bar version'),
            ]
          end

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq ["There is no verified pact between verison foo and bar version"] }
          its(:counts) { is_expected.to eq success: 0, failed: 0, unknown: 1 }
        end

        context "when there is something unexpected about the data and the resolved selector cannot be found" do
          let(:rows) { [row_1] }

          let(:resolved_selectors) do
            [
              double('selector',
                pacticipant_id: 3,
                pacticipant_name: "Foo",
                pacticipant_version_number: "4ee06460f10e8207ad904fa9fa6c4842e462ab59",
                pacticipant_version_id: 10,
                latest_tagged_version_that_does_not_exist?: false,
                specified_version_that_does_not_exist?: false,
                description: "version 4ee06460f10e8207ad904fa9fa6c4842e462ab59 of Foo"
              )
            ]
          end

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq ["There is no verified pact between version 4ee06460f10e8207ad904fa9fa6c4842e462ab59 of Foo and Baz (unresolved version)"] }

          it "logs a warning" do
            expect(logger).to receive(:warn).with(/Could not find the resolved version/)
            subject.reasons
          end
        end
      end
    end
  end
end
