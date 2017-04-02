require_relative 'base_decorator'
require_relative 'embedded_version_decorator'
require 'pact_broker/api/decorators/timestamps'
require 'pact_broker/domain'

module PactBroker

  module Api

    module Decorators

      class PacticipantDecorator < BaseDecorator

        property :name
        property :repository_url, as: :repositoryUrl

        property :latest_version, as: :'latest-version', :class => PactBroker::Domain::Version, :extend => PactBroker::Api::Decorators::EmbeddedVersionDecorator, :embedded => true, writeable: false

        include Timestamps

        link :self do | options |
          pacticipant_url(options[:base_url], represented)
        end

        link 'latest-version' do | options |
          latest_version_url(options[:base_url], represented)
        end

        link :versions do | options |
          versions_url(options[:base_url], represented)
        end

      end
    end
  end
end
