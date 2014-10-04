require_relative 'base_decorator'
require_relative 'version_decorator'
require 'pact_broker/api/decorators/timestamps'

module PactBroker

  module Api

    module Decorators

      class PacticipantRepresenter < BaseDecorator

        property :name
        property :repository_url, as: :repositoryUrl

        property :latest_version, as: :'latest-version', :class => PactBroker::Models::Version, :extend => PactBroker::Api::Decorators::VersionRepresenter, :embedded => true, writeable: false

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
