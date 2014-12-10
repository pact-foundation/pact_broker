require_relative 'base_decorator'
require_relative 'pact_pacticipant_decorator'
require_relative 'timestamps'

module PactBroker

  module Api

    module Decorators

      class TagDecorator < BaseDecorator

        include Timestamps

        link :self do | options |
          {
            title: 'Tag',
            name: represented.name,
            href: tag_url(options[:base_url], represented)
          }
        end

        link :version do | options |
          {
            title: 'Version',
            name: represented.version.number,
            href: version_url(options.fetch(:base_url), represented.version)
          }
        end

        link :pacticipant do | options |
          {
            title: 'Pacticipant',
            name: represented.version.pacticipant.name,
            href: pacticipant_url(options.fetch(:base_url), represented.version.pacticipant)
          }
        end

      end
    end
  end
end