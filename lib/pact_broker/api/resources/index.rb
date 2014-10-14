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
              'pb:self' =>
              {
                href: base_url,
                title: 'The Pact Broker index page',
                templated: false
              },
              'pb:latest-pacts' =>
              {
                href: base_url + '/pacts/latest',
                title: 'Retrieve latest pacts',
                templated: false
              },
              'pb:pacticipants' =>
              {
                href: base_url + '/pacticipants',
                title: 'Retrieve pacticipants',
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