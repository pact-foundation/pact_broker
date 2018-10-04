require 'pact_broker/api/resources/base_resource'
require 'json'

module PactBroker
  module Api
    module Resources

      class Index < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def to_json
          { _links: links }.to_json
        end

        def links
          {
            'self' =>
            {
              href: base_url,
              title: 'Index',
              templated: false
            },
            'pb:publish-pact' => {
              href: base_url + '/pacts/provider/{provider}/consumer/{consumer}/version/{consumerApplicationVersion}',
              title: 'Publish a pact',
              templated: true
            },
            'pb:latest-pact-versions' =>
            {
              href: base_url + '/pacts/latest',
              title: 'Latest pact versions',
              templated: false
            },
            'pb:tagged-pact-versions' =>
            {
              href: base_url + '/pacts/provider/{provider}/consumer/{consumer}/tag/{tag}',
              title: 'All versions of a pact for a given consumer, provider and consumer version tag',
              templated: false
            },
            'pb:pacticipants' =>
            {
              href: base_url + '/pacticipants',
              title: 'Pacticipants',
              templated: false
            },
            'pb:latest-provider-pacts' =>
            {
              href: base_url + '/pacts/provider/{provider}/latest',
              title: 'Latest pacts by provider',
              templated: true
            },
            'pb:latest-provider-pacts-with-tag' =>
            {
              href: base_url + '/pacts/provider/{provider}/latest/{tag}',
              title: 'Latest pacts for provider with the specified tag',
              templated: true
            },
            'pb:provider-pacts-with-tag' =>
            {
              href: base_url + '/pacts/provider/{provider}/tag/{tag}',
              title: 'All pact versions for the provider with the specified consumer version tag',
              templated: true
            },
            'pb:provider-pacts' =>
            {
              href: base_url + '/pacts/provider/{provider}',
              title: 'All pact versions for the specified provider',
              templated: true
            },
            'pb:latest-version' => {
              href: base_url + '/pacticipants/{pacticipant}/latest-version',
              title: 'Latest pacticipant version',
              templated: true
            },
            'pb:latest-tagged-version' => {
              href: base_url + '/pacticipants/{pacticipant}/latest-version/{tag}',
              title: 'Latest pacticipant version with the specified tag',
              templated: true
            },
            'pb:webhooks' => {
              href: base_url + '/webhooks',
              title: 'Webhooks',
              templated: false
            },
            'pb:integrations' => {
              href: base_url + '/integrations',
              title: 'Integrations',
              templated: false
            },
            'beta:pending-provider-pacts' =>
            {
              href: base_url + '/pacts/provider/{provider}/pending',
              title: 'Pending pact versions for the specified provider',
              templated: true
            },
            'curies' =>
            [{
              name: 'pb',
              href: base_url + '/doc/{rel}?context=index',
              templated: true
            },{
              name: 'beta',
              href: base_url + '/doc/{rel}?context=index',
              templated: true
            }]
          }
        end
      end
    end
  end
end
