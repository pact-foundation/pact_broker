require_relative 'base_decorator'
require_relative 'pact_pacticipant_decorator'
require 'pact_broker/api/decorators/timestamps'

module PactBroker

  module Api

    module Decorators

      class PactVersionDecorator < BaseDecorator

        include Timestamps

        property :consumer_version, as: :consumerVersion, embedded: true, decorator: EmbeddedVersionDecorator

        link :self do | options |
          {
            href: pact_url(options[:base_url], represented),
            title: represented.name
          }
        end

      end
    end
  end
end
