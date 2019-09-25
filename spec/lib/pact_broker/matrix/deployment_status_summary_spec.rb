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
            consumer: foo,
            provider: bar,
            consumer_version: foo_version,
            provider_version: bar_version,
            consumer_name: "Foo",
            consumer_id: 1,
            consumer_version_id: 1,
            provider_name: "Bar",
            provider_id: 2,
            success: row_1_success,
            pacticipant_names: %w{Foo Bar}
          )
        end

        let(:row_2) do
          double(Row,
            consumer: foo,
            provider: baz,
            consumer_version: foo_version,
            provider_version: baz_version,
            consumer_name: "Foo",
            consumer_id: 1,
            consumer_version_id: 1,
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
            ResolvedSelector.new(
              pacticipant_id: 1,
              pacticipant_name: "Foo",
              pacticipant_version_number: "ddec8101dabf4edf9125a69f9a161f0f294af43c",
              pacticipant_version_id: 10
            ),
            ResolvedSelector.new(
              pacticipant_id: 2,
              pacticipant_name: "Bar",
              pacticipant_version_number: "14131c5da3abf323ccf410b1b619edac76231243",
              pacticipant_version_id: 11
            ),
            ResolvedSelector.new(
             pacticipant_id: 3,
             pacticipant_name: "Baz",
             pacticipant_version_number: "4ee06460f10e8207ad904fa9fa6c4842e462ab59",
             pacticipant_version_id: 12
            ),
          ]
        end

        subject { DeploymentStatusSummary.new(rows, resolved_selectors, integrations) }

        context "when there is a row for all integrations" do
          its(:deployable?) { is_expected.to be true }
          its(:reasons) { is_expected.to eq [Successful.new] }
          its(:counts) { is_expected.to eq success: 2, failed: 0, unknown: 0 }
        end

        context "when there are no rows" do
          let(:rows) { [] }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) do
            is_expected.to eq [
              PactNotVerifiedByRequiredProviderVersion.new(resolved_selectors.first, resolved_selectors[1]),
              PactNotVerifiedByRequiredProviderVersion.new(resolved_selectors.first, resolved_selectors.last)
            ]
          end
          its(:counts) { is_expected.to eq success: 0, failed: 0, unknown: 2 }
        end

        context "when one or more of the success flags are nil" do
          let(:row_1_success) { nil }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq [PactNotEverVerifiedByProvider.new(resolved_selectors.first, resolved_selectors[1]) ] }
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 1 }
        end

        context "when one or more of the success flags are false" do
          let(:row_1_success) { false }

          its(:deployable?) { is_expected.to be false }
          its(:reasons) { is_expected.to eq [VerificationFailed.new(resolved_selectors.first, resolved_selectors[1])] }
          its(:counts) { is_expected.to eq success: 1, failed: 1, unknown: 0 }
        end

        context "when there is a provider relationship missing" do
          let(:rows) { [row_1] }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq [PactNotVerifiedByRequiredProviderVersion.new(resolved_selectors.first, resolved_selectors.last)] }
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
          its(:reasons) { is_expected.to eq [Successful.new] }
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 0 }
        end

        context "when there are no rows, and no missing downstream providers and the provider was specified in the query" do
          let(:rows) { [] }
          let(:integrations) do
            [
              Integration.new(1, "Foo", 2, "Bar", false),
              Integration.new(3, "Baz", 2, "Bar", false)
            ]
          end

          its(:deployable?) { is_expected.to be true }
          its(:reasons) { is_expected.to eq [NoDependenciesMissing.new] }
          its(:counts) { is_expected.to eq success: 0, failed: 0, unknown: 0 }
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
          its(:reasons) { is_expected.to eq [PactNotVerifiedByRequiredProviderVersion.new(resolved_selectors.first, resolved_selectors.last)] }
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 1 }
        end

        context "when there are no inferred selectors and the pact has not ever been verified" do
          # This happens when the user has not specified a version of the provider (eg no 'latest' and/or 'tag')
          # so the "add inferred selectors" code in the Matrix::Repository has not run
          # AND the pact has not been verified
          # eg.
          # bundle exec bin/pact-broker can-i-deploy --broker-base-url http://localhost:9292 --pacticipant Foo --version 1.1.0
          let(:rows) { [row_1] }
          let(:row_1_success) { nil }

          let(:dummy_selector) do
            ResolvedSelector.new(
              pacticipant_id: 2,
              pacticipant_name: "Bar",
              pacticipant_version_id: 10,
              pacticipant_version_number: "14131c5da3abf323ccf410b1b619edac76231243",
              pact_publication_ids: [],
              verification_ids: [],
              latest: nil,
              tag: nil,
              type: :inferred
            )
          end

          before do
            resolved_selectors.delete_at(1)
            resolved_selectors.delete_at(1)
            integrations.delete_at(1)
          end

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq [PactNotEverVerifiedByProvider.new(resolved_selectors.first, dummy_selector)] }
        end
      end
    end
  end
end
