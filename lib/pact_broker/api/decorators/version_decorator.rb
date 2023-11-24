require_relative "base_decorator"
require_relative "embedded_tag_decorator"
require_relative "embedded_branch_version_decorator"

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
