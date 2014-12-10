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

        link :self do | options |
          {
            title: 'Version',
            name: represented.number,
            href: version_url(options.fetch(:base_url), represented)
          }
        end

        link :pacticipant do | options |
          {
            title: 'Pacticipant',
            name: represented.pacticipant.name,
            href: pacticipant_url(options.fetch(:base_url), represented.pacticipant)
          }
        end

      end
    end
  end
end
