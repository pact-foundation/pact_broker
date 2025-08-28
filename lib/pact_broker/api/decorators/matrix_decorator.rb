require "ostruct"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/api/decorators/reason_decorator"
require "pact_broker/api/decorators/format_date_time"
require "pact_broker/api/decorators/embedded_branch_version_decorator"
require "pact_broker/api/decorators/embedded_environment_decorator"

module PactBroker
  module Api
    module Decorators
      class MatrixDecorator
        include PactBroker::Api::PactBrokerUrls
        include FormatDateTime

        def initialize(query_results_with_deployment_status_summary)
          @query_results_with_deployment_status_summary = query_results_with_deployment_status_summary
        end

        def to_json(*args, **kwargs)
          to_hash(*args, **kwargs).to_json
        end

        def to_hash(user_options:, **_other)
          {
            summary: {
              deployable: deployable,
              reason: reason
            },
            notices: notices,
            matrix: matrix(user_options[:base_url])
          }.tap do | hash |
            hash[:summary].merge!(query_results_with_deployment_status_summary.deployment_status_summary.counts)
          end
        end

        def deployable
          query_results_with_deployment_status_summary.deployment_status_summary.deployable?
        end

        def reason
          query_results_with_deployment_status_summary
            .deployment_status_summary
            .reasons
            .collect{ | reason | reason_decorator_class.new(reason).to_s }
            .join("\n")
        end

        private

        attr_reader :query_results_with_deployment_status_summary

        def reason_decorator_class
          ReasonDecorator
        end

        def matrix(base_url)
          query_results_with_deployment_status_summary.considered_rows.collect do | line |
            hash_for_row(line, base_url)
          end + query_results_with_deployment_status_summary.ignored_rows.collect do | line |
            hash_for_row(line, base_url).merge(ignored: true)
          end
        end

        def hash_for_row(line, base_url)
          provider = OpenStruct.new(name: line.provider_name)
          consumer = OpenStruct.new(name: line.consumer_name)
          consumer_version = OpenStruct.new(number: line.consumer_version_number, pacticipant: consumer)
          provider_version = line.provider_version_number ? OpenStruct.new(number: line.provider_version_number, pacticipant: provider) : nil
          line_hash(consumer, provider, consumer_version, provider_version, line, base_url)
        end

        # rubocop: disable Metrics/ParameterLists
        def line_hash(consumer, provider, consumer_version, provider_version, line, base_url)
          {
            consumer: consumer_hash(line, consumer, consumer_version, base_url),
            provider: provider_hash(line, provider, provider_version, base_url),
            pact: pact_hash(line, base_url),
            verificationResult: verification_hash(line, base_url)
          }
        end
        # rubocop: enable Metrics/ParameterLists

        def consumer_hash(line, consumer, consumer_version, base_url)
          {
            name: line.consumer_name,
            version: {
              number: line.consumer_version_number,
              branch: line.consumer_version_branch_versions.last&.branch_name,
              branches: branches(line.consumer_version_branch_versions, base_url), # TODO delete this
              branchVersions: branches(line.consumer_version_branch_versions, base_url),
              environments: environments(line.consumer_version_deployed_versions, line.consumer_version_released_versions, base_url),
              _links: {
                self: {
                  href: version_url(base_url, consumer_version)
                }
              },
              tags: tags(line.consumer_version_tags, base_url)
            },
            _links: {
              self: {
                href: pacticipant_url(base_url, consumer)
              }
            }
          }
        end

        def branches(branch_versions, base_url)
          branch_versions.collect do | branch_version |
            PactBroker::Api::Decorators::EmbeddedBranchVersionDecorator.new(branch_version).to_hash(user_options: { base_url: base_url })
          end
        end

        def environments(deployed_versions, released_versions, base_url)
          (deployed_versions + released_versions).sort_by(&:created_at).collect(&:environment).uniq.collect do | environment |
            environment_decorator_class.new(environment).to_hash(user_options: { base_url: base_url })
          end
        end

        def environment_decorator_class
          PactBroker::Api::Decorators::EmbeddedEnvironmentDecorator
        end

        def tags(tags, base_url)
          tags.sort_by(&:created_at).collect do | tag |
            {
              name: tag.name,
              latest: tag.latest?,
              _links: {
                self: {
                  href: tag_url(base_url, tag)
                }
              }
            }
          end
        end

        def provider_hash(line, provider, provider_version, base_url)
          hash = {
            name: line.provider_name,
            version: nil,
            _links: {
              self: {
                href: pacticipant_url(base_url, provider)
              }
            }
          }

          if !line.provider_version_number.nil?
            hash[:version] = {
              number: line.provider_version_number,
              branch: line.provider_version_branch_versions.last&.branch_name,
              branches: branches(line.provider_version_branch_versions, base_url), # TODO delete this
              branchVersions: branches(line.provider_version_branch_versions, base_url),
              environments: environments(line.provider_version_deployed_versions, line.provider_version_released_versions, base_url),
              _links: {
                self: {
                  href: version_url(base_url, provider_version)
                }
              },
              tags: tags(line.provider_version_tags, base_url)
            }
          end

          hash
        end

        def pact_hash(line, base_url)
          {
            createdAt: format_date_time(line.pact_created_at),
            _links: {
              self: {
                href: pact_url(base_url, line)
              }
            }
          }
        end

        def verification_hash(line, base_url)
          if !line.success.nil?
            url_params = {
              consumer_name: line.consumer_name,
              provider_name: line.provider_name,
              pact_version_sha: line.pact_version_sha,
              consumer_version_number: line.consumer_version_number,
              verification_number: line.verification_number
            }
            {
              success: line.success,
              verifiedAt: format_date_time(line.verification_executed_at),
              _links: {
                self: {
                  href: verification_url_from_params(url_params, base_url)
                }
              }
            }
          else
            nil
          end
        end

        def notices
          query_results_with_deployment_status_summary
            .deployment_status_summary
            .reasons
            .collect{ | reason | { type: reason.type, text: reason_decorator_class.new(reason).to_s } }
        end
      end
    end
  end
end

