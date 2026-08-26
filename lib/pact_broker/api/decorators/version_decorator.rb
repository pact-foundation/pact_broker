require_relative "base_decorator"
require_relative "embedded_tag_decorator"
require_relative "embedded_branch_version_decorator"
require_relative "format_date_time"

module PactBroker
  module Api
    module Decorators
      class VersionDecorator < BaseDecorator

        property :number, writeable: false
        # TODO delete branches in preference for branchVersions
        collection :branch_versions, as: :branches, embedded: true, writeable: false, extend: PactBroker::Api::Decorators::EmbeddedBranchVersionDecorator
        collection :branch_versions, as: :branchVersions, embedded: true, writeable: false, extend: PactBroker::Api::Decorators::EmbeddedBranchVersionDecorator
        property :build_url, as: :buildUrl

        collection :tags, embedded: true, :extend => PactBroker::Api::Decorators::EmbeddedTagDecorator, class: OpenStruct

        include Timestamps

        # Returns the list of associations that must be eager loaded to efficiently render a version
        # when this decorator is used in a collection (eg. VersionsDecorator)
        # The associations that need to be eager loaded for the VersionDecorator
        # are hand coded
        # @return <Array>
        def self.eager_load_associations
          [
            :pacticipant,
            { pact_publications: [:consumer, :provider, { pact_version: :latest_verification }, :tags, :head_pact_publications_for_tags] },
            { branch_versions: [:version, :branch_head, { branch: :pacticipant }] },
            { tags: :head_tag }
          ]
        end

        link :self do | options |
          {
            title: "Version",
            name: represented.number,
            # This decorator is used for multiple Version resources, so dynamically fetch the current resource URL
            href: options.fetch(:resource_url)
          }
        end

        link :'pb:pacticipant' do | options |
          {
            title: "Pacticipant",
            name: represented.pacticipant.name,
            href: pacticipant_url(options.fetch(:base_url), represented.pacticipant)
          }
        end

        link :'pb:tag' do | options |
          {
            href: version_url(options.fetch(:base_url), represented) + "/tags/{tag}",
            title: "Get, create or delete a tag for this pacticipant version",
            templated: true
          }
        end

        link :'pb:latest-verification-results-where-pacticipant-is-consumer' do | options |
          {
            title: "Latest verification results for consumer version",
            href: latest_verifications_for_consumer_version_url(represented, options.fetch(:base_url))
          }
        end

        links :'pb:pact-versions' do | context |
          sorted_pacts.collect do | pact |
            {
              title: "Pact",
              name: pact.name,
              href: pact_url(context[:base_url], pact),
            }
          end
        end

        links :'pb:deployed-environments' do | context |
          # NB: use fully-qualified ::Hash. The tins gem shadows the bare `Hash`
          # constant in this scope, so `is_a?(Hash)` returns false even for a real
          # Hash (this is the collection-vs-single-item branch: the collection
          # resource passes a version_id-keyed Hash, the single resource an Array).
          deployed_versions = context.dig(:deployed_versions)
          deployed_versions = deployed_versions[represented.id] if deployed_versions.is_a?(::Hash)
          deployed_versions&.collect do | deployed_version |
            {
              title: "Version deployed to #{deployed_version.environment.display_name}",
              name: deployed_version.environment.display_name,
              href: deployed_version_url(deployed_version, context.fetch(:base_url)),
              currently_deployed: deployed_version.currently_deployed,
              deployed_at: FormatDateTime.call(deployed_version.created_at),
              undeployed_at: FormatDateTime.call(deployed_version.undeployed_at)
            }.tap do |hash|
              hash[:application_instance] = deployed_version.application_instance unless deployed_version.application_instance.nil?
            end
          end
        end

        links :'pb:released-environments' do | context |
          # NB: use fully-qualified ::Hash. The tins gem shadows the bare `Hash`
          # constant in this scope, so `is_a?(Hash)` returns false even for a real
          # Hash (this is the collection-vs-single-item branch: the collection
          # resource passes a version_id-keyed Hash, the single resource an Array).
          released_versions = context.dig(:released_versions)
          released_versions = released_versions[represented.id] if released_versions.is_a?(::Hash)
          released_versions&.collect do | released_version |
            {
              title: "Version released to #{released_version.environment.display_name}",
              name: released_version.environment.display_name,
              href: released_version_url(released_version, context.fetch(:base_url)),
              currently_supported: released_version.currently_supported,
              released_at: FormatDateTime.call(released_version.created_at),
              support_ended_at: FormatDateTime.call(released_version.support_ended_at)
            }
          end
        end

        links :'pb:record-deployment' do | context |
          context[:environments]&.collect do | environment |
            {
              title: "Record deployment to #{environment.display_name}",
              name: environment.name,
              href: deployed_versions_for_version_and_environment_url(represented, environment, context.fetch(:base_url))
            }
          end
        end

        links :'pb:record-release' do | context |
          context[:environments]&.collect do | environment |
            {
              title: "Record release to #{environment.display_name}",
              name: environment.name,
              href: released_versions_for_version_and_environment_url(represented, environment, context.fetch(:base_url))
            }
          end
        end

        curies do | options |
          [{
            name: :pb,
            href: options.fetch(:base_url) + "/doc/{rel}?context=version",
            templated: true
          }]
        end

        def from_hash(hash, options = {})
          if hash["tags"]
            updated_hash = hash.dup
            updated_hash["_embedded"] ||= {}
            updated_hash["_embedded"]["tags"] = updated_hash.delete("tags")
            super(updated_hash, options)
          else
            super
          end
        end

        private

        def sorted_pacts
          represented.pact_publications.sort{ |a, b| a.provider_name.downcase <=> b.provider_name.downcase }
        end
      end
    end
  end
end
