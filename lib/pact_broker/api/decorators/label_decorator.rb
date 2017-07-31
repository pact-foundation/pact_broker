require_relative 'base_decorator'
require_relative 'pact_pacticipant_decorator'
require_relative 'timestamps'

module PactBroker
  module Api
    module Decorators
      class LabelDecorator < BaseDecorator

        property :name

        include Timestamps

        link :self do | options |
          {
            title: 'Label',
            name: represented.name,
            href: label_url(represented, options[:base_url])
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
