require 'pact_broker/api/decorators/matrix_decorator'
require 'pact_broker/matrix/query_results_with_deployment_status_summary'
require 'pact_broker/matrix/deployment_status_summary'

module PactBroker
  module Api
    module Decorators
      describe MatrixDecorator do
        describe "to_json" do
          let(:verification_date) { DateTime.new(2017, 12, 31) }
          let(:pact_created_at) { DateTime.new(2017, 1, 1) }
          let(:row_1_success) { true }
          let(:row_2_success) { true }
          let(:row_1) do
            double('PactBroker::Matrix::Row',
              {
                consumer_name: "Consumer",
                consumer_version_number: "1.0.0",
                consumer_version_tags: consumer_version_tags,
                provider_version_tags: provider_version_tags,
                pact_version_sha: "1234",
                pact_created_at: pact_created_at,
                provider_version_number: "4.5.6",
                provider_name: "Provider",
                success: row_1_success,
                verification_number: 1,
                verification_build_url: nil,
                verification_executed_at: verification_date
              }
            )
          end

          let(:row_2) do
            double('PactBroker::Matrix::Row',
              {
                consumer_name: "Consumer",
                consumer_version_number: "1.0.0",
                consumer_version_tags: [],
                pact_version_sha: "1234",
                pact_created_at: pact_created_at,
                provider_version_number: nil,
                provider_name: "Provider",
                success: row_2_success,
                verification_number: nil,
                verification_build_url: nil,
                verification_executed_at: verification_date
              }
            )
          end

          let(:consumer_hash) do
            {
              name: 'Consumer',
              _links: {
                self: {
                  href: 'http://example.org/pacticipants/Consumer'
                }
              },
              version: {
                number: '1.0.0',
                _links: {
                  self: {
                    href: 'http://example.org/pacticipants/Consumer/versions/1.0.0'
                  }
                },
                tags: [
                  {
                    name: 'prod',
                    latest: true,
                    _links: {
                      self: {
                        href: 'http://example.org/pacticipants/Consumer/versions/1.0.0/tags/prod'
                      }
                    }
                  }
                ]
              }
            }
          end

          let(:provider_hash) do
            {
              name: 'Provider',
              _links: {
                self: {
                  href: 'http://example.org/pacticipants/Provider'
                }
              },
              version: {
                number: '4.5.6',
                _links: {
                  self: {
                    href: 'http://example.org/pacticipants/Provider/versions/4.5.6'
                  }
                },
                tags: [
                  {
                    name: 'master',
                    latest: false,
                    _links: {
                      self: {
                        href: 'http://example.org/pacticipants/Provider/versions/4.5.6/tags/master'
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
                  href: "http://example.org/pacts/provider/Provider/consumer/Consumer/pact-version/1234/verification-results/1"
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

          let(:consumer_version_tags) do
            [
              double("tag", name: "prod", latest?: true, version: consumer_version)
            ]
          end

          let(:provider_version) { double("provider version", number: "4.5.6", pacticipant: double("provider", name: "Provider")) }

          let(:provider_version_tags) do
            [
              double("tag", name: "master", latest?: false, version: provider_version)
            ]
          end

          let(:query_results) do
            double('QueryResults',
              rows: [row_1, row_2],
              selectors: selectors,
              options: options,
              resolved_selectors: resolved_selectors,
              integrations: integrations
            )
          end
          let(:query_results_with_deployment_status_summary){ PactBroker::Matrix::QueryResultsWithDeploymentStatusSummary.new(query_results, deployment_status_summary)}
          let(:selectors) { nil }
          let(:integrations){ [] }
          let(:options) { nil }
          let(:resolved_selectors) { nil }
          let(:counts) { { success: 1 } }
          let(:deployment_status_summary) do
            instance_double('PactBroker::Matrix::DeploymentStatusSummary', reasons: ['foo', 'bar'], deployable?: deployable, counts: counts)
          end
          let(:deployable) { true }
          let(:json) { MatrixDecorator.new(query_results_with_deployment_status_summary).to_json(user_options: { base_url: 'http://example.org' }) }
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
            expect(parsed_json[:summary][:reason]).to eq "foo\nbar"
            expect(parsed_json[:summary][:success]).to eq 1
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
        end
      end
    end
  end
end
