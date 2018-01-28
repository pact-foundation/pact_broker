require_relative 'base_decorator'
require_relative 'embedded_version_decorator'
require_relative 'embedded_label_decorator'
require_relative 'timestamps'
require 'pact_broker/domain'

module PactBroker
  module Api
    module Decorators
      class PacticipantDecorator < BaseDecorator

        property :name
        property :repository_url, as: :repositoryUrl

        property :latest_version, as: :latestVersion, :class => PactBroker::Domain::Version, extend: PactBroker::Api::Decorators::EmbeddedVersionDecorator, embedded: true, writeable: false
        collection :labels, :class => PactBroker::Domain::Label, extend: PactBroker::Api::Decorators::EmbeddedLabelDecorator, embedded: true

        include Timestamps

        link :self do | options |
          pacticipant_url(options[:base_url], represented)
        end

        link :'pb:versions' do | options |
          versions_url(options[:base_url], represented)
        end

        # TODO deprecate in v3
        # URL isn't implemented
        # link 'latest-version' do | options |
        #   {
        #     title: "Deprecated - use pb:latest-version",
        #     href: latest_version_url(options[:base_url], represented)
        #   }
        # end

        # TODO deprecate in v3
        link :versions do | options |
          {
            title: "Deprecated - use pb:versions",
            href: versions_url(options[:base_url], represented)
          }
        end

        def to_hash options
          h = super
          dasherized = DasherizedVersionDecorator.new(represented).to_hash(options)
          if dasherized['_embedded']
            if dasherized['_embedded']['latest-version']
              dasherized['_embedded']['latest-version']['title'] = 'DEPRECATED - please use latestVersion'
              dasherized['_embedded']['latest-version']['name'] = 'DEPRECATED - please use latestVersion'
            end
            h['_embedded'] ||= {}
            h['_embedded'].merge!(dasherized['_embedded'])
          end
          h
        end
      end

      class DasherizedVersionDecorator < BaseDecorator
        # TODO deprecate in v3
        property :latest_version, as: :'latest-version', :class => PactBroker::Domain::Version, extend: PactBroker::Api::Decorators::EmbeddedVersionDecorator, embedded: true, writeable: false
      end
    end
  end
end
