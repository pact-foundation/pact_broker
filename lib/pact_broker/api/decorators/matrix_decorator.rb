require 'ostruct'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/api/decorators/reason_decorator'
require 'pact_broker/api/decorators/format_date_time'

module PactBroker
  module Api
    module Decorators
      class MatrixDecorator
        include PactBroker::Api::PactBrokerUrls
        include FormatDateTime

        def initialize(query_results_with_deployment_status_summary)
          @query_results_with_deployment_status_summary = query_results_with_deployment_status_summary
        end

        def to_json(options)
          to_hash(options).to_json
        end

        def to_hash(options)
          {
            summary: {
              deployable: deployable,
              reason: reason
            },
            matrix: matrix(options[:user_options][:base_url])
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
            .collect{ | reason | ReasonDecorator.new(reason).to_s }
            .join("\n")
        end

        private

        attr_reader :query_results_with_deployment_status_summary

        def matrix(base_url)
          query_results_with_deployment_status_summary.rows.collect do | line |
            provider = OpenStruct.new(name: line.provider_name)
            consumer = OpenStruct.new(name: line.consumer_name)
            consumer_version = OpenStruct.new(number: line.consumer_version_number, pacticipant: consumer)
            line_hash(consumer, provider, consumer_version, line, base_url)
          end
        end

        def line_hash(consumer, provider, consumer_version, line, base_url)
          {
            consumer: consumer_hash(line, consumer, consumer_version, base_url),
            provider: provider_hash(line, provider, base_url),
            pact: pact_hash(line, base_url),
            verificationResult: verification_hash(line, base_url)
          }
        end

        def consumer_hash(line, consumer, consumer_version, base_url)
          {
            name: line.consumer_name,
            version: {
              number: line.consumer_version_number,
              _links: {
                self: {
                  href: version_url(base_url, consumer_version)
                }
              }
            },
            _links: {
              self: {
                href: pacticipant_url(base_url, consumer)
              }
            }
          }
        end

        def provider_hash(line, provider, base_url)
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
            hash[:version] = { number: line.provider_version_number }
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
            url_params = { consumer_name: line.consumer_name,
              provider_name: line.provider_name,
              pact_version_sha: line.pact_version_sha,
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
      end
    end
  end
end

