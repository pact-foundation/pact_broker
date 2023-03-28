require "roar/json/hal"
require "pact_broker/api/pact_broker_urls"
require_relative "embedded_version_decorator"
require_relative "pagination_links"
require "pact_broker/domain/pacticipant"
require "pact_broker/api/decorators/pacticipant_decorator"

module PactBroker
  module Api
    module Decorators
      class PacticipantCollectionDecorator < BaseDecorator

        collection :entries, :as => :pacticipants, :class => PactBroker::Domain::Pacticipant, :extend => PactBroker::Api::Decorators::PacticipantDecorator, embedded: true

        include PaginationLinks

        link :self do | options |
          pacticipants_url options[:base_url]
        end

        link :'pb:pacticipants-with-label' do | options |
          {
            title: "Find pacticipants by label",
            href: "#{pacticipants_url(options[:base_url])}/label/{label}",
            templated: true
          }
        end

        links :'pb:pacticipants' do | options |
          represented.collect{ | pacticipant | {:href => pacticipant_url(options[:base_url], pacticipant), title: "Pacticipant", name: pacticipant.name } }
        end

        # TODO deprecate in v3
        links :pacticipants do | options |
          represented.collect{ | pacticipant | {:href => pacticipant_url(options[:base_url], pacticipant), :title => pacticipant.name, name: "DEPRECATED - please use pb:pacticipants" } }
        end
      end

      class DeprecatedPacticipantDecorator < PactBroker::Api::Decorators::PacticipantDecorator
        property :title, getter: ->(_) { "DEPRECATED - Please use the embedded pacticipants collection" }
      end

      class NonEmbeddedPacticipantCollectionDecorator < BaseDecorator
        collection :entries, :as => :pacticipants, :class => PactBroker::Domain::Pacticipant, :extend => DeprecatedPacticipantDecorator, embedded: false
      end

      # TODO deprecate this - breaking change for v 3.0
      class DeprecatedPacticipantCollectionDecorator < PacticipantCollectionDecorator
        def to_hash(*options, **kwargs)
          embedded_pacticipant_hash = super
          non_embedded_pacticipant_hash = NonEmbeddedPacticipantCollectionDecorator.new(represented).to_hash(*options, **kwargs)
          embedded_pacticipant_hash.merge(non_embedded_pacticipant_hash)
        end
      end
    end
  end
end
