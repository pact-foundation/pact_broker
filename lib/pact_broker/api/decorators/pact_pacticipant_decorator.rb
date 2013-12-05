require_relative 'pact_broker_urls'
require_relative 'version_decorator'
require_relative 'base_decorator'


module PactBroker

  module Api

    module Decorators

      class PactPacticipantRepresenter < BaseDecorator

        property :name
        property :repository_url
        property :version, :class => "PactBroker::Models::Version", :extend => PactBroker::Api::Decorators::VersionRepresenter, :embedded => true

        link :self do | options |
          pacticipant_url(options[:base_url], represented)
        end

      end
    end
  end
end