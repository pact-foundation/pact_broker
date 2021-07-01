module PactBroker
  module Pacts
    module PactPublicationSelectorDatasetModule
      def for_provider_and_consumer_version_selector provider, selector
        # Does not yet support "all pacts for specified tag" - that code is still in the Pact::Repository
        query = for_provider(provider)
        query = query.for_consumer(PactBroker::Domain::Pacticipant.find_by_name(selector.consumer)) if selector.consumer
        # Do this last so that the provider/consumer criteria get included in the "latest" query before the join, rather than after
        query = query.latest_for_consumer_branch(selector.branch) if selector.latest_for_branch?
        query = query.latest_for_consumer_tag(selector.tag) if selector.latest_for_tag?
        query = query.for_currently_deployed_versions(selector.environment) if selector.currently_deployed?
        query = query.for_currently_supported_versions(selector.environment) if selector.currently_supported?
        query = query.overall_latest if selector.overall_latest?
        query
      end

      def for_currently_deployed_versions(environment_name)
        deployed_versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:deployed_versions][:version_id]
        }
        currently_deployed_versions_join = {
          Sequel[:deployed_versions][:id] => Sequel[:currently_deployed_version_ids][:deployed_version_id]
        }
        environments_join = {
          Sequel[:deployed_versions][:environment_id] => Sequel[:environments][:id],
          Sequel[:environments][:name] => environment_name
        }.compact

        query = self
        if no_columns_selected?
          query = query.select_all_qualified.select_append(Sequel[:environments][:name].as(:environment_name), Sequel[:deployed_versions][:target].as(:target))
        end
        query
          .join(:deployed_versions, deployed_versions_join)
          .join(:currently_deployed_version_ids, currently_deployed_versions_join)
          .join(:environments, environments_join)
      end

      def for_currently_supported_versions(environment_name)
        released_versions_join = {
          Sequel[:pact_publications][:consumer_version_id] => Sequel[:released_versions][:version_id],
          Sequel[:released_versions][:support_ended_at] => nil
        }
        environments_join = {
          Sequel[:released_versions][:environment_id] => Sequel[:environments][:id],
          Sequel[:environments][:name] => environment_name
        }.compact

        query = self
        if no_columns_selected?
          query = query.select_all_qualified.select_append(Sequel[:environments][:name].as(:environment_name))
        end
        query
          .join(:released_versions, released_versions_join)
          .join(:environments, environments_join)
      end

    end
  end
end
