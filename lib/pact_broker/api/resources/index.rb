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
              'pb:webhooks' =>
              {
                href: base_url + '/webhooks',
                title: 'Webhooks',
                templated: false
              },'curies' =>
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