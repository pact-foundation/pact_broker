require "pact_broker/api/resources/base_resource"
require "pact_broker/feature_toggle"
require "json"

module PactBroker
  module Api
    module Resources
      class Index < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def to_json
          { _links: links }.to_json
        end

        # rubocop: disable Metrics/MethodLength
        def links
          links_hash = {
            "self" =>
            {
              href: base_url,
              title: "Index",
              templated: false
            },
            "pb:publish-pact" => {
              href: base_url + "/pacts/provider/{provider}/consumer/{consumer}/version/{consumerApplicationVersion}",
              title: "Publish a pact",
              templated: true
            },
            "pb:publish-contracts" => {
              href: base_url + "/contracts/publish",
              title: "Publish contracts",
              templated: false
            },
            "pb:latest-pact-versions" =>
            {
              href: base_url + "/pacts/latest",
              title: "Latest pact versions",
              templated: false
            },
            "pb:tagged-pact-versions" =>
            {
              href: base_url + "/pacts/provider/{provider}/consumer/{consumer}/tag/{tag}",
              title: "All versions of a pact for a given consumer, provider and consumer version tag",
              templated: false
            },
            "pb:pacticipants" =>
            {
              href: base_url + "/pacticipants",
              title: "Pacticipants",
              templated: false
            },
            "pb:pacticipant" =>
            {
              href: base_url + "/pacticipants/{pacticipant}",
              title: "Fetch pacticipant by name",
              templated: true
            },
            "pb:latest-provider-pacts" =>
            {
              href: base_url + "/pacts/provider/{provider}/latest",
              title: "Latest pacts by provider",
              templated: true
            },
            "pb:latest-provider-pacts-with-tag" =>
            {
              href: base_url + "/pacts/provider/{provider}/latest/{tag}",
              title: "Latest pacts for provider with the specified tag",
              templated: true
            },
            "pb:provider-pacts-with-tag" =>
            {
              href: base_url + "/pacts/provider/{provider}/tag/{tag}",
              title: "All pact versions for the provider with the specified consumer version tag",
              templated: true
            },
            "pb:provider-pacts" =>
            {
              href: base_url + "/pacts/provider/{provider}",
              title: "All pact versions for the specified provider",
              templated: true
            },
            "pb:latest-version" => {
              href: base_url + "/pacticipants/{pacticipant}/latest-version",
              title: "Latest pacticipant version",
              templated: true
            },
            "pb:latest-tagged-version" => {
              href: base_url + "/pacticipants/{pacticipant}/latest-version/{tag}",
              title: "Latest pacticipant version with the specified tag",
              templated: true
            },
            "pb:webhooks" => {
              href: base_url + "/webhooks",
              title: "Webhooks",
              templated: false
            },
            "pb:webhook" => {
              href: base_url + "/webhooks/{uuid}",
              title: "Webhook",
              templated: true
            },
            "pb:integrations" => {
              href: base_url + "/integrations",
              title: "Integrations",
              templated: false
            },
            "pb:pacticipant-version-tag" =>
            {
              href: base_url + "/pacticipants/{pacticipant}/versions/{version}/tags/{tag}",
              title: "Get, create or delete a tag for a pacticipant version",
              templated: true
            },
            "pb:pacticipant-branch" =>
            {
              href: base_url + "/pacticipants/{pacticipant}/branches/{branch}",
              title: "Get or delete a pacticipant branch",
              templated: true
            },
            "pb:pacticipant-branch-version" =>
            {
              href: base_url + "/pacticipants/{pacticipant}/branches/{branch}/versions/{version}",
              title: "Get or add/create a pacticipant version for a branch",
              templated: true
            },
            "pb:pacticipant-version" =>
            {
              href: base_url + "/pacticipants/{pacticipant}/versions/{version}",
              title: "Get, create or delete a pacticipant version",
              templated: true
            },
            "pb:metrics" =>
            {
              href: base_url + "/metrics",
              title: "Get Pact Broker metrics",
            },
            "pb:can-i-deploy-pacticipant-version-to-tag" =>
            {
              href: base_url + "/can-i-deploy?pacticipant={pacticipant}&version={version}&to={tag}",
              title: "Determine if an application version can be safely deployed to an environment identified by the given tag",
              templated: true
            },
            "pb:can-i-deploy-pacticipant-version-to-environment" =>
            {
              href: base_url + "/can-i-deploy?pacticipant={pacticipant}&version={version}&environment={environment}",
              title: "Determine if an application version can be safely deployed to an environment",
              templated: true
            },
            "pb:provider-pacts-for-verification" => {
              href: base_url + "/pacts/provider/{provider}/for-verification",
              title: "Pact versions to be verified for the specified provider",
              templated: true
            },
            "beta:provider-pacts-for-verification" => {
              name: "beta",
              href: base_url + "/pacts/provider/{provider}/for-verification",
              title: "DEPRECATED - please use pb:provider-pacts-for-verification",
              templated: true
            },
            "curies" =>
            [{
              name: "pb",
              href: base_url + "/doc/{rel}?context=index",
              templated: true
            },{
              name: "beta",
              href: base_url + "/doc/{rel}?context=index",
              templated: true
            }]
          }

          links_hash["pb:environments"] = {
            title: "Environments",
            href: environments_url(base_url),
            templated: false
          }

          links_hash["pb:environment"] = {
            title: "Environment",
            href: environments_url(base_url) + "/{uuid}",
            templated: true
          }

          if PactBroker.feature_enabled?("disable_pacts_for_verification", true)
            links_hash.delete("pb:provider-pacts-for-verification")
            links_hash.delete("beta:provider-pacts-for-verification")
          end

          links_hash
        end
        # rubocop: enable Metrics/MethodLength

        def policy_name
          :'index::index'
        end
      end
    end
  end
end
