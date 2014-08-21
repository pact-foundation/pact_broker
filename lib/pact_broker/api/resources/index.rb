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

        # TODO change to use request.base_url to avoid params getting included!!!
        def to_json
          {
            _links: {
              'pb:self' =>
              {
                href: request.uri.to_s,
                title: 'The Pact Broker index page',
                templated: false
              },
              'pb:latest-pacts' =>
              {
                href: request.uri.to_s + 'pacts/latest',
                title: 'Retrieve latest pacts',
                templated: false
              },
              'pb:pacticipants' =>
              {
                href: request.uri.to_s + 'pacticipants',
                title: 'Retrieve pacticipants',
                templated: false
              },
              'pb:webhooks' =>
              {
                href: request.uri.to_s + 'webhooks',
                title: 'Webhooks',
                templated: false
              },'curies' =>
              [{
                name: 'pb',
                href: request.uri.to_s + 'doc/{rel}',
                templated: true
              }]
            }
          }.to_json
        end


      end
    end

  end
end