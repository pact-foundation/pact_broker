require "pact_broker/api/decorators/matrix_decorator"
require "pact_broker/matrix/query_results_with_deployment_status_summary"
require "pact_broker/matrix/deployment_status_summary"
require "pact_broker/matrix/matrix_row"

module PactBroker
  module Api
    module Decorators
      describe MatrixDecorator do
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
            instance_double("PactBroker::Matrix::MatrixRow",
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
            instance_double("PactBroker::Matrix::MatrixRow",
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
                success: row_2_success,
                verification_number: nil,
                verification_executed_at: verification_date
              }
            )
          end

          let(:consumer_hash) do
            {
              name: "Consumer",
              _links: {
                self: {
                  href: "http://example.org/pacticipants/Consumer"
                }
              },
              version: {
                number: "1.0.0",
                branch: "main",
                branches: [
                  name: "main",
                  _links: {

                  }
                ],
                branchVersions: [
                  name: "main",
                  _links: {

                  }
                ],
                environments: [
                  {
                    name: "test",
                    displayName: "Test"
                  },
                  {
                    name: "production",
                    displayName: "Production"
                  }
                ],
                _links: {
                  self: {
                    href: "http://example.org/pacticipants/Consumer/versions/1.0.0"
                  }
                },
                tags: [
                  {
                    name: "prod",
                    latest: true,
                    _links: {
                      self: {
                        href: "http://example.org/pacticipants/Consumer/versions/1.0.0/tags/prod"
                      }
                    }
                  }
                ]
              }
            }
          end

          let(:provider_hash) do
            {
              name: "Provider",
              _links: {
                self: {
                  href: "http://example.org/pacticipants/Provider"
                }
              },
              version: {
                number: "4.5.6",
                branch: "feat/x",
                branchVersions: [
                  {
                    name: "feat/x",
                    latest: true
                  }
                ],
                environments: [
                  {
                    name: "test",
                    displayName: "Test"
                  },
                  {
                    name: "production",
                    displayName: "Production"
                  }
                ],
                _links: {
                  self: {
                    href: "http://example.org/pacticipants/Provider/versions/4.5.6"
                  }
                },
                tags: [
                  {
                    name: "master",
                    latest: false,
                    _links: {
                      self: {
                        href: "http://example.org/pacticipants/Provider/versions/4.5.6/tags/master"
                      }
                    }
                  }
                ]
              }
            }
          end

          let(:verification_hash) do
            {
              success: true,
              verifiedAt: "2017-12-31T00:00:00+00:00",
              _links: {
                self: {
                  href: "http://example.org/pacts/provider/Provider/consumer/Consumer/pact-version/1234/metadata/Y3ZuPTEuMC4w/verification-results/1"
                }
              }
            }
          end

          let(:pact_hash) do
            {
              createdAt: "2017-01-01T00:00:00+00:00",
              _links: {
                self: {
                  href: "http://example.org/pacts/provider/Provider/consumer/Consumer/version/1.0.0"
                }
              }
            }
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
          let(:json) { MatrixDecorator.new(query_results_with_deployment_status_summary).to_json(user_options: { base_url: "http://example.org" }) }
          let(:parsed_json) { JSON.parse(json, symbolize_names: true) }

          it "includes the consumer details" do
            expect(parsed_json[:matrix][0][:consumer]).to match_pact consumer_hash
          end

          it "includes the provider details" do
            expect(parsed_json[:matrix][0][:provider]).to match_pact provider_hash
          end

          it "includes the verification details" do
            expect(parsed_json[:matrix][0][:verificationResult]).to eq verification_hash
          end

          it "includes the pact details" do
            expect(parsed_json[:matrix][0][:pact]).to eq pact_hash
          end

          it "includes a summary" do
            expect(parsed_json[:summary][:deployable]).to eq true
            expect(parsed_json[:summary][:reason]).to eq "foo\nfoo"
            expect(parsed_json[:summary][:success]).to eq 1
          end

          it "includes notices" do
            expect(parsed_json[:notices][0]).to eq text: "foo", type: "info"
            expect(parsed_json[:notices][1]).to eq text: "foo", type: "warning"
          end

          context "when the pact has not been verified" do
            before do
              allow(row_2).to receive(:success).and_return(nil)
              allow(row_2).to receive(:verification_executed_at).and_return(nil)
            end

            let(:verification_hash) { nil }

            it "has empty provider details" do
              expect(parsed_json[:matrix][1][:provider]).to eq provider_hash.merge(version: nil)
            end

            it "has a nil verificationResult" do
              expect(parsed_json[:matrix][1][:verificationResult]).to eq verification_hash
            end
          end

          context "with ignored rows" do
            let(:ignored_rows) { [row_1] }

            it "includes the considered and ignored rows" do
              expect(parsed_json[:matrix].size).to eq 3
              expect(parsed_json[:matrix].first).to_not have_key(:ignored)
            end

            it "includes the ignored flag" do
              expect(parsed_json[:matrix].last[:ignored]).to be true
            end
          end
        end
      end
    end
  end
end
