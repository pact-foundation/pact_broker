require "pact_broker/api/decorators/matrix_text_decorator"
require "pact_broker/matrix/query_results_with_deployment_status_summary"
require "pact_broker/matrix/deployment_status_summary"
require "pact_broker/matrix/quick_row"

module PactBroker
  module Api
    module Decorators
      describe MatrixTextDecorator do
        describe "to_json" do
          before do
            allow_any_instance_of(ReasonDecorator).to receive(:to_s).and_return("foo")
            allow_any_instance_of(PactBroker::Api::PactBrokerUrls).to receive(:branch_version_url).and_return("branch_version_url")
          end
          let(:verification_date) { DateTime.new(2017, 12, 31) }
          let(:pact_created_at) { DateTime.new(2017, 1, 1) }
          let(:row_1_success) { true }
          let(:row_2_success) { true }
          let(:row_1) do
            instance_double("PactBroker::Matrix::QuickRow",
              {
                consumer_name: "Consumer",
                consumer_version_number: "1.0.0",
                consumer_version_branch_versions: consumer_version_branch_versions,
                consumer_version_deployed_versions: deployed_versions,
                consumer_version_released_versions: released_versions,
                consumer_version_tags: consumer_version_tags,
                provider_version_tags: provider_version_tags,
                pact_version_sha: "1234",
                pact_created_at: pact_created_at,
                provider_version_number: "4.5.6",
                provider_version_branch_versions: provider_version_branch_versions,
                provider_version_deployed_versions: deployed_versions,
                provider_version_released_versions: released_versions,
                provider_name: "Provider",
                success: row_1_success,
                verification_number: 1,
                verification_executed_at: verification_date
              }
            )
          end

          let(:row_2) do
            instance_double("PactBroker::Matrix::QuickRow",
              {
                consumer_name: "Consumer",
                consumer_version_number: "1.0.0",
                consumer_version_branch_versions: [],
                consumer_version_deployed_versions: [],
                consumer_version_released_versions: [],
                consumer_version_tags: [],
                pact_version_sha: "1234",
                pact_created_at: pact_created_at,
                provider_version_number: nil,
                provider_version_branch_versions: [],
                provider_version_deployed_versions: [],
                provider_version_released_versions: [],
                provider_name: "Provider",
                success: nil,
                verification_number: nil,
                verification_executed_at: verification_date
              }
            )
          end

          let(:consumer_version) { double("consumer version", number: "1.0.0", pacticipant: double("consumer", name: "Consumer")) }

          let(:consumer_version_branch_versions) do
            [ instance_double("PactBroker::Versions::BranchVersion", branch_name: "main", latest?: true) ]
          end

          let(:deployed_versions) do
            [
              instance_double("PactBroker::Deployments::DeployedVersion", environment: test_environment, created_at: DateTime.new(2021, 1, 1))
            ]
          end

          let(:released_versions) do
            [
              instance_double("PactBroker::Deployments::ReleasedVersion", environment: prod_environment, created_at: DateTime.new(2021, 1, 2))
            ]
          end

          let(:test_environment) do
            instance_double("PactBroker::Deployments::Environment", uuid: "uuid", production: false, name: "test", display_name: "Test", created_at: DateTime.now, updated_at: DateTime.now ).as_null_object
          end

          let(:prod_environment) do
            instance_double("PactBroker::Deployments::Environment", uuid: "uuid", production: true, name: "production", display_name: "Production", created_at: DateTime.now, updated_at: DateTime.now ).as_null_object
          end

          let(:consumer_version_tags) do
            [
              double("tag", name: "prod", latest?: true, version: consumer_version, created_at: DateTime.now )
            ]
          end

          let(:provider_version) { double("provider version", number: "4.5.6", pacticipant: double("provider", name: "Provider")) }

          let(:provider_version_branch_versions) do
            [ instance_double("PactBroker::Versions::BranchVersion", branch_name: "feat/x", latest?: true) ]
          end

          let(:provider_version_tags) do
            [
              double("tag", name: "master", latest?: false, version: provider_version, created_at: DateTime.now)
            ]
          end

          let(:query_results) do
            double("QueryResults",
              considered_rows: [row_1, row_2],
              ignored_rows: ignored_rows,
              selectors: selectors,
              options: options,
              resolved_selectors: resolved_selectors,
              integrations: integrations
            )
          end
          let(:ignored_rows) { [] }
          let(:query_results_with_deployment_status_summary){ PactBroker::Matrix::QueryResultsWithDeploymentStatusSummary.new(query_results, deployment_status_summary)}
          let(:selectors) { nil }
          let(:integrations){ [] }
          let(:options) { nil }
          let(:resolved_selectors) { nil }
          let(:counts) { { success: 1 } }
          let(:deployment_status_summary) do
            instance_double("PactBroker::Matrix::DeploymentStatusSummary", reasons: [reason_1, reason_2], deployable?: deployable, counts: counts)
          end
          let(:reason_1) { instance_double("PactBroker::Matrix::Reason", type: "info") }
          let(:reason_2) { instance_double("PactBroker::Matrix::Reason", type: "warning") }
          let(:deployable) { true }
          let(:text) { MatrixTextDecorator.new(query_results_with_deployment_status_summary).to_text(user_options: { base_url: "http://example.org" }) }

          it "returns text" do
            Approvals.verify(text, :name => "can_i_deploy_text_1", format: :txt)
          end
        end
      end
    end
  end
end
