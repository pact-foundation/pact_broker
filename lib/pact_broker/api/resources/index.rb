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
          ["GET"]
        end

        def to_json
          {
            _links: {
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
                title: 'Latest pacts by provider with the specified tag',
                templated: true
              },
              'pb:latest-version' => {
                href: base_url + '/pacticipants/{pacticipant}/versions/latest',
                title: 'Latest pacticipant version',
                templated: true
              },
              'pb:latest-tagged-version' => {
                href: base_url + '/pacticipants/{pacticipant}/versions/latest/{tag}',
                title: 'Latest pacticipant version with the specified tag',
                templated: true
              },
              'pb:webhooks' => {
                href: base_url + '/webhooks',
                title: 'Webhooks',
                templated: false
              },
              'curies' =>
              [{
                name: 'pb',
                href: base_url + '/doc/{rel}',
                templated: true
              }]
            }
          }.to_json
        end
      end
    end
  end
end
