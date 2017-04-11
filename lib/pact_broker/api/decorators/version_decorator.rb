require_relative 'base_decorator'
require_relative 'embedded_tag_decorator'

module PactBroker
  module Api
    module Decorators
      class VersionDecorator < BaseDecorator

        property :number

        collection :tags, embedded: true, :extend => PactBroker::Api::Decorators::EmbeddedTagDecorator

        link :self do | options |
          {
            title: 'Version',
            name: represented.number,
            href: version_url(options.fetch(:base_url), represented)
          }
        end

        link :'pb:latest-verifications' do | options |
          {
            title: "Latest verifications for consumer version",
            href: latest_verifications_for_consumer_version_url(represented, options.fetch(:base_url))
          }
        end

        link :pacticipant do | options |
          {
            title: 'Pacticipant',
            name: represented.pacticipant.name,
            href: pacticipant_url(options.fetch(:base_url), represented.pacticipant)
          }
        end

        curies do | options |
          [{
            name: :pb,
            href: options.fetch(:base_url) + '/doc/{rel}',
            templated: true
          }]
        end
      end
    end
  end
end
