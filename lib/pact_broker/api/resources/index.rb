require 'pact_broker/api/resources/base_resource'
require 'json'

module PactBroker::Api

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
            'index' => [
              {
                href: request.uri.to_s,
                title: 'The index page',
                templated: false
              }
            ],
            'latest-pacts' => [
              {
                href: request.uri.to_s + 'pacts/latest',
                title: 'Retrieve latest pacts',
                templated: false
              }
            ],
            'pacticpants' => [
              {
                href: request.uri.to_s + 'pacticipants',
                title: 'Retrieve pacticipants',
                templated: false
              }
            ]
          }
        }.to_json
      end

    end
  end

end
