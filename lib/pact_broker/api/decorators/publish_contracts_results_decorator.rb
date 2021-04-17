require 'pact_broker/api/decorators/base_decorator'
require 'pact_broker/api/decorators/publish_contract_decorator'
require 'pact_broker/api/decorators/embedded_version_decorator'

module PactBroker
  module Api
    module Decorators
      class PublishContractsResultsDecorator < BaseDecorator
        camelize_property_names

        property :logs, getter: ->(represented:, **) { represented.logs.collect(&:to_h) }

        property :pacticipant, embedded: true, extend: EmbeddedPacticipantDecorator
        property :version, embedded: true, extend: EmbeddedVersionDecorator

        link :'pb:pacticipant' do | options |
          {
            title: "Pacticipant",
            name: represented.pacticipant.name,
            href: pacticipant_url(options.fetch(:base_url), represented.pacticipant)
          }
        end

        link :'pb:pacticipant-version' do | options |
          {
            title: "Pacticipant version",
            name: represented.version.number,
            href: version_url(options.fetch(:base_url), represented.version)
          }
        end

        links :'pb:pacticipant-version-tags' do | options |
          represented.tags.collect do | tag |
            {
              title: "Tag",
              name: tag.name,
              href: tag_url(options.fetch(:base_url), tag)
            }
          end
        end

        links :'pb:contracts' do | options |
          represented.contracts.collect do | contract |
            {
              title: 'Pact',
              name: contract.name,
              href: pact_url(options.fetch(:base_url), contract)
            }
          end
        end
      end
    end
  end
end
