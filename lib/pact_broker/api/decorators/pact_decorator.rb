require_relative "base_decorator"
require "pact_broker/json"
require "pact_broker/api/decorators/timestamps"

module PactBroker
  module Api
    module Decorators
      class PactDecorator < BaseDecorator

        include Timestamps

        def to_hash(options = {})
          parsed_content = represented.content_hash
          if parsed_content.is_a?(::Hash)
            parsed_content.merge super
          else
            parsed_content
          end
        end

        link :self do | options |
          {
            title: "Pact",
            name: represented.name,
            href: pact_url(options.fetch(:base_url), represented)
          }
        end

        link :'pb:consumer' do | options |
          {
            title: "Consumer",
            name: represented.consumer.name,
            href: pacticipant_url(options.fetch(:base_url), represented.consumer)
          }
        end

        link :'pb:consumer-version' do | options |
          {
            title: "Consumer version",
            name: represented.consumer_version_number,
            href: version_url(options.fetch(:base_url), represented.consumer_version)
          }
        end

        links :'pb:consumer-versions' do | options |
          if options[:consumer_versions]
            options[:consumer_versions].collect do | consumer_version |
              {
                title: "Consumer version",
                name: consumer_version.number,
                href: version_url(options.fetch(:base_url), consumer_version)
              }
            end
          end
        end

        link :'pb:provider' do | options |
          {
            title: "Provider",
            name: represented.provider.name,
            href: pacticipant_url(options.fetch(:base_url), represented.provider)
          }
        end

        link :'pb:pact-version' do | options |
          {
            title: "Pact content version permalink",
            name: represented.pact_version_sha,
            href: pact_version_url(represented, options.fetch(:base_url))
          }
        end

        link :'pb:latest-pact-version' do | options |
          {
            title: "Latest version of this pact",
            href: latest_pact_url(options.fetch(:base_url), represented)

          }
        end

        link :'pb:all-pact-versions' do | options |
          {
            title: "All versions of this pact",
            href: pact_versions_url(represented.consumer.name, represented.provider.name, options.fetch(:base_url))
          }
        end

        link :'pb:latest-untagged-pact-version' do | options |
          {
            title: "Latest untagged version of this pact",
            href: latest_untagged_pact_url(represented, options.fetch(:base_url))
          }
        end

        link :'pb:latest-tagged-pact-version' do | options |
          {
            title: "Latest tagged version of this pact",
            href: "#{latest_pact_url(options.fetch(:base_url), represented)}/{tag}",
            templated: true
          }
        end

        link :'pb:previous-distinct' do | options |
          {
            title: "Previous distinct version of this pact",
            href: previous_distinct_pact_version_url(represented, options.fetch(:base_url))
          }
        end

        link :'pb:diff-previous-distinct' do | options |
          {
            title: "Diff with previous distinct version of this pact",
            href: previous_distinct_diff_url(represented, options[:metadata], options.fetch(:base_url))

          }
        end

        link :'pb:diff' do | options |
          {
            title: "Diff with another specified version of this pact",
            href: templated_diff_url(represented, options.fetch(:base_url)),
            templated: true

          }
        end

        link :'pb:pact-webhooks' do | options |
          {
            title: "Webhooks for the pact between #{represented.consumer.name} and #{represented.provider.name}",
            href: webhooks_for_consumer_and_provider_url(represented.consumer, represented.provider, options.fetch(:base_url))
          }
        end

        link :'pb:consumer-webhooks' do | options |
          {
            title: "Webhooks for all pacts with consumer #{represented.consumer.name}",
            href: consumer_webhooks_url(represented.consumer, options.fetch(:base_url))
          }
        end

        link :'pb:consumer-webhooks' do | options |
          {
            title: "Webhooks for all pacts with provider #{represented.provider.name}",
            href: consumer_webhooks_url(represented.provider, options.fetch(:base_url))
          }
        end

        link :'pb:tag-prod-version' do | options |
          {
            title: "PUT to this resource to tag this consumer version as 'production'",
            href: tags_url(options.fetch(:base_url), represented.consumer_version) + "/prod"
          }
        end

        link :'pb:tag-version' do | options |
          {
            title: "PUT to this resource to tag this consumer version",
            href: tags_url(options.fetch(:base_url), represented.consumer_version) + "/{tag}"
          }
        end

        link :'pb:publish-verification-results' do | options |
          {
            title: "Publish verification results",
            href: verification_publication_url(represented, options.fetch(:base_url), options[:metadata])
          }
        end

        link :'pb:latest-verification-results' do | options |
          {
            href: latest_verification_for_pact_url(represented, options.fetch(:base_url))
          }
        end

        link :'pb:triggered-webhooks' do | options |
          {
            title: "Webhooks triggered by the publication of this pact",
            href: pact_triggered_webhooks_url(represented, options.fetch(:base_url))
          }
        end

        link :'pb:matrix-for-consumer-version' do | options |
          {
            title: "View matrix rows for the consumer version to which this pact belongs",
            href: matrix_for_pacticipant_version_url(represented.consumer_version, options.fetch(:base_url))
          }
        end

        curies do | options |
          [{
            name: :pb,
            href: options[:base_url] + "/doc/{rel}?context=pact",
            templated: true
          }]
        end
      end
    end
  end
end