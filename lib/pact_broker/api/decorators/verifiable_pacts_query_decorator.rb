require_relative 'base_decorator'
require_relative 'verifiable_pact_decorator'
require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    module Decorators
      class VerifiablePactsQueryDecorator < BaseDecorator
        collection :provider_version_tags

        collection :consumer_version_selectors, class: OpenStruct do
          property :tag
          property :latest, default: true
        end


        def from_hash(*args)
          # Should remember how to do this via Representable...
          result = super
          result.consumer_version_selectors = [] if result.consumer_version_selectors.nil?
          result.provider_version_tags = [] if result.provider_version_tags.nil?
          result
        end
      end
    end
  end
end
