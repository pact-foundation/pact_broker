require_relative "base_decorator"
require_relative "embedded_version_decorator"
require_relative "embedded_label_decorator"
require_relative "timestamps"
require "pact_broker/feature_toggle"

require "pact_broker/domain"

module PactBroker
  module Api
    module Decorators
      class PacticipantDecorator < BaseDecorator
        camelize_property_names

        property :name
        property :display_name
        property :repository_url
        property :repository_name
        property :repository_namespace
        property :main_branch

        property :latest_version, as: :latestVersion, :class => PactBroker::Domain::Version, extend: PactBroker::Api::Decorators::EmbeddedVersionDecorator, embedded: true, writeable: false
        collection :labels, :class => PactBroker::Domain::Label, extend: PactBroker::Api::Decorators::EmbeddedLabelDecorator, embedded: true

        include Timestamps

        # The associations that should be eager loaded on the Pacticipant so that this
        # decorator can be used without any extra calls to the database.
        # @return Array<Symbol>
        def self.eager_load_associations
          [:labels, :latest_version]
        end

        link :self do | options |
          pacticipant_url(options[:base_url], represented)
        end

        link :'pb:versions' do | options |
          versions_url(options[:base_url], represented)
        end

        link :'pb:version' do | options |
          {
            title: "Get, create or delete a pacticipant version",
            href: templated_version_url_for_pacticipant(represented.name, options[:base_url]),
            templated: true
          }
        end

        link :'pb:version-tag' do | options |
          {
            title: "Get, create or delete a tag for a version of #{represented.name}",
            href: templated_tag_url_for_pacticipant(represented.name, options[:base_url]),
            templated: true
          }
        end

        link :'pb:branch-version' do | options |
          {
            title: "Get or add/create a version for a branch of #{represented.name}",
            href: templated_branch_version_url_for_pacticipant(represented.name, options[:base_url]),
            templated: true
          }
        end

        link :'pb:label' do | options |
          {
            title: "Get, create or delete a label for #{represented.name}",
            href: templated_label_url_for_pacticipant(represented.name, options[:base_url]),
            templated: true
          }
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

        link :'pb:can-i-deploy-badge' do | options |
          {
            title: "Can I Deploy #{represented.name} badge",
            href: templated_can_i_deploy_badge_url(represented.name, options[:base_url]),
            templated: true
          }
        end

        link :'pb:can-i-deploy-branch-to-environment-badge' do | options |
          {
            title: "Can I Deploy #{represented.name} from branch to environment badge",
            href: templated_can_i_deploy_branch_to_environment_badge_url(represented.name, options[:base_url]),
            templated: true
          }
        end

        curies do | options |
          [{
            name: :pb,
            href: options[:base_url] + "/doc/{rel}?context=pacticipant",
            templated: true
          }]
        end

        # representable passes through the kwargs from to_json as normal args
        def to_hash(options)
          h = super
          dasherized = DasherizedVersionDecorator.new(represented).to_hash(options)
          if dasherized["_embedded"]
            if dasherized["_embedded"]["latest-version"]
              dasherized["_embedded"]["latest-version"]["title"] = "DEPRECATED - please use latestVersion"
              dasherized["_embedded"]["latest-version"]["name"] = "DEPRECATED - please use latestVersion"
            end
            h["_embedded"] ||= {}
            h["_embedded"].merge!(dasherized["_embedded"])
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
