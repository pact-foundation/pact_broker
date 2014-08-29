require_relative 'base_decorator'
require_relative 'pact_pacticipant_decorator'

module PactBroker

  module Api

    module Decorators

      class EmbeddedVersionDecorator < BaseDecorator

        property :number

        link :self do | options |
          version_url(options[:base_url], represented)
        end
      end

      class PactVersionDecorator < BaseDecorator


        property :createdAt, getter: lambda { |_|  created_at.to_time.localtime.xmlschema }, writeable: false
        property :updatedAt, getter: lambda { |_| updated_at.to_time.localtime.xmlschema }, writeable: false

        property :consumer_version, as: :consumerVersion, embedded: true, decorator: EmbeddedVersionDecorator


        link :self do | options |
          {
            href: pact_url(options.base_url, represented),
            title: represented.name
          }

        end

      end
    end
  end
end
