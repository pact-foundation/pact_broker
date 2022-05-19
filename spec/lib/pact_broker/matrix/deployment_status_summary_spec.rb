require "pact_broker/matrix/deployment_status_summary"
require "pact_broker/matrix/quick_row"
require "pact_broker/matrix/query_results"
require "pact_broker/matrix/integration"
require "pact_broker/matrix/resolved_selector"
require "pact_broker/matrix/query_results"


module PactBroker
  module Matrix
    describe DeploymentStatusSummary do

      before do
        allow(subject).to receive(:logger).and_return(logger)
      end

      let(:logger) { double("logger").as_null_object }

      describe ".call" do
        let(:rows) { [row_1, row_2] }
        # Foo => Bar
        let(:row_1) do
          double(QuickRow,
            consumer: foo,
            provider: bar,
            consumer_version: foo_version,
            provider_version: bar_version,
            consumer_name: foo.name,
            consumer_id: foo.id,
            consumer_version_id: foo_version.id,
            provider_name: bar.name,
            provider_id: bar.id,
            success: row_1_success,
            pacticipant_names: [foo.name, bar.name],
            verification: verification_1
          )
        end

        # Foo => Baz
        let(:row_2) do
          double(QuickRow,
            consumer: foo,
            provider: baz,
            consumer_version: foo_version,
            provider_version: baz_version,
            consumer_name: foo.name,
            consumer_id: foo.id,
            consumer_version_id: foo_version.id,
            provider_name: baz.name,
            provider_id: baz.id,
            success: true,
            pacticipant_names: [foo.name, baz.name],
            verification: verification_2
          )
        end

        let(:row_1_success) { true }

        let(:integrations) do
          [
            Integration.new(1, "Foo", 2, "Bar", true),
            Integration.new(1, "Foo", 3, "Baz", true)
          ]
        end

        let(:foo) { double("foo", id: 1, name: "Foo") }
        let(:bar) { double("bar", id: 2, name: "Bar") }
        let(:baz) { double("baz", id: 3, name: "Baz") }
        let(:foo_version) { double("foo version", number: "ddec8101dabf4edf9125a69f9a161f0f294af43c", id: 10)}
        let(:bar_version) { double("bar version", number: "14131c5da3abf323ccf410b1b619edac76231243", id: 11)}
        let(:baz_version) { double("baz version", number: "4ee06460f10e8207ad904fa9fa6c4842e462ab59", id: 12)}
        let(:verification_1) { double("verification 1", interactions_missing_test_results: []) }
        let(:verification_2) { double("verification 2", interactions_missing_test_results: []) }

        let(:resolved_selectors) do
          [
            ResolvedSelector.new(
              pacticipant_id: foo.id,
              pacticipant_name: foo.name,
              pacticipant_version_number: foo_version.number,
              pacticipant_version_id: foo_version.id
            ),
            ResolvedSelector.new(
              pacticipant_id: bar.id,
              pacticipant_name: bar.name,
              pacticipant_version_number: bar_version.number,
              pacticipant_version_id: bar_version.id
            ),
            ResolvedSelector.new(
             pacticipant_id: baz.id,
             pacticipant_name: baz.name,
             pacticipant_version_number: baz_version.number,
             pacticipant_version_id: baz_version.id
            )
          ]
        end

        let(:ignored_rows) { [] }
        let(:resolved_ignore_selectors) { [] }

        let(:query_results) do
          instance_double(PactBroker::Matrix::QueryResults,
            considered_rows: rows,
            ignored_rows: ignored_rows,
            resolved_selectors: resolved_selectors,
            resolved_ignore_selectors: resolved_ignore_selectors,
            integrations: integrations,
            rows: rows + ignored_rows,
            options: options
          )
        end

        let(:options) { { environment_name: "prod" } }

        subject { DeploymentStatusSummary.new(query_results) }

        context "when there is a row for all integrations" do
          its(:deployable?) { is_expected.to be true }
          its(:reasons) { is_expected.to eq [Successful.new] }
          its(:counts) { is_expected.to eq success: 2, failed: 0, unknown: 0 }
        end

        context "when there are resolved_ignore_selectors" do
          let(:resolved_ignore_selectors) { [ResolvedSelector.new()] }

          its(:counts) { is_expected.to have_key(:ignored) }
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

          context "when that row is ignored" do
            let(:resolved_ignore_selectors) { [instance_double("PactBroker::Matrix::ResolvedSelector", pacticipant_or_version_does_not_exist?: false).as_null_object] }
            let(:rows) { [row_2] }
            let(:ignored_rows) { [row_1] }

            its(:deployable?) { is_expected.to be true }

            its(:reasons) { is_expected.to eq [Successful.new] }
            its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 0, ignored: 1 }
          end
        end

        context "when one or more of the success flags are false" do
          let(:row_1_success) { false }

          its(:deployable?) { is_expected.to be false }
          its(:reasons) { is_expected.to eq [VerificationFailed.new(resolved_selectors.first, resolved_selectors[1])] }
          its(:counts) { is_expected.to eq success: 1, failed: 1, unknown: 0 }

          context "when that row is ignored" do
            let(:resolved_ignore_selectors) { [instance_double("PactBroker::Matrix::ResolvedSelector", pacticipant_or_version_does_not_exist?: false).as_null_object] }
            let(:rows) { [row_2] }
            let(:ignored_rows) { [row_1] }

            its(:deployable?) { is_expected.to be true }
            its(:reasons) { is_expected.to eq [Successful.new] }
            its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 0, ignored: 1 }
          end
        end

        # TODO
        # I think this is an impossible scenario now that the left outer join returns a row with blank verification fields
        context "when there is a provider relationship missing [don't think this is possible any more]" do
          let(:rows) { [row_1] }

          its(:deployable?) { is_expected.to be nil }
          its(:reasons) { is_expected.to eq [PactNotVerifiedByRequiredProviderVersion.new(resolved_selectors.first, resolved_selectors.last)] }
          its(:counts) { is_expected.to eq success: 1, failed: 0, unknown: 1 }
        end

        context "when there is a consumer row missing a verification and only the provider was specified in the query" do
          let(:rows) { [row_1] }

          let(:integrations) do
            [
              Integration.new(1, "Foo", 2, "Bar", true),
              Integration.new(3, "Baz", 2, "Bar", false) # the integration missing a verification
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

        context "when there is a provider integration that does not have a matching row and only the consumer was specified in the query" do
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
              pacticipant_id: bar.id,
              pacticipant_name: bar.name,
              pacticipant_version_id: bar_version.id,
              pacticipant_version_number: bar_version.number,
              latest: nil,
              tag: nil,
              branch: nil,
              main_branch: nil,
              environment_name: nil,
              type: :inferred,
              ignore: false,
              one_of_many: false,
              original_selector: {}
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

        context "when there are ignore selectors that don't match any pacticipant or version" do
          let(:resolved_ignore_selectors) { [instance_double("PactBroker::Matrix::ResolvedSelector", pacticipant_or_version_does_not_exist?: true).as_null_object] }

          its(:reasons) { is_expected.to eq [IgnoreSelectorDoesNotExist.new(resolved_ignore_selectors.first), PactBroker::Matrix::Successful.new] }
        end

        context "when there is a selector without a specified pacticipant version number" do
          let(:resolved_selectors) do
            [
              ResolvedSelector.new(
                pacticipant_id: foo.id,
                pacticipant_name: foo.name,
                pacticipant_version_number: foo_version.number,
                pacticipant_version_id: foo_version.id,
                type: :specified,
                original_selector: { latest: true, tag: "asdf" }
              )
            ]
          end

          its(:reasons) { is_expected.to include SelectorWithoutPacticipantVersionNumberSpecified.new }
        end

        context "when there is no to tag or environment specified" do
          let(:options) { { } }

          its(:reasons) { is_expected.to include NoEnvironmentSpecified.new }
        end
      end
    end
  end
end
