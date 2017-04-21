require_relative 'base_decorator'
require 'pact_broker/json'
require 'pact_broker/api/decorators/timestamps'

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
            title: 'Pact',
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

        link :'pb:provider' do | options |
          {
            title: "Provider",
            name: represented.provider.name,
            href: pacticipant_url(options.fetch(:base_url), represented.provider)
          }
        end

        link :'pb:latest-pact-version' do | options |
          {
            title: "Pact",
            name: "Latest version of this pact",
            href: latest_pact_url(options.fetch(:base_url), represented)

          }
        end

        link :'pb:previous-distinct' do | options |
          {
            title: "Pact",
            name: "Previous distinct version of this pact",
            href: previous_distinct_pact_version_url(represented, options.fetch(:base_url))
          }
        end

        link :'pb:diff-previous-distinct' do | options |
          {
            title: "Diff",
            name: "Diff with previous distinct version of this pact",
            href: previous_distinct_diff_url(represented, options.fetch(:base_url))

          }
        end

        # link :'pb:pact-versions' do | options |
        #   {
        #     title: "All versions of the pact between #{represented.consumer.name} and #{represented.provider.name}",
        #     href: pact_versions_url(represented.consumer.name, represented.provider.name, options.fetch(:base_url))
        #   }
        # end

        link :'pb:pact-webhooks' do | options |
          {
            title: "Webhooks for the pact between #{represented.consumer.name} and #{represented.provider.name}",
            href: webhooks_for_pact_url(represented.consumer, represented.provider, options.fetch(:base_url))
          }
        end

        link :'pb:tag-prod-version' do | options |
          {
            title: "Tag this version as 'production'",
            href: tags_url(options.fetch(:base_url), represented.consumer_version) + "/prod"
          }
        end

        link :'pb:tag-version' do | options |
          {
            title: "Tag version",
            href: tags_url(options.fetch(:base_url), represented.consumer_version) + "/{tag}"
          }
        end

        link :'pb:publish-verification' do | options |
          {
            title: "Publish verification",
            href: verification_publication_url(represented, options.fetch(:base_url))
          }
        end

        curies do | options |
          [{
            name: :pb,
            href: options[:base_url] + '/doc/{rel}',
            templated: true
          }]
        end

      end
    end
  end
end