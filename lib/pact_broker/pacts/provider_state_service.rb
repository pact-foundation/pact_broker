require "pact_broker/services"
require "pact_broker/pacts/selectors"
require "pact_broker/pacts/pact_publication"
require "pact_broker/repositories"


module PactBroker
  module Pacts
    class ProviderStateService
      # extend self
      extend PactBroker::Services
      extend PactBroker::Repositories::Scopes

      def self.list_provider_states(provider)
        query = scope_for(PactPublication).eager_for_domain_with_content.for_provider_and_consumer_version_selector(provider, PactBroker::Pacts::Selector.latest_for_main_branch)
        query.all.flat_map do | pact_publication |
          { "providerStates" => pact_publication.to_domain.content_object.provider_states, "consumer" => pact_publication.to_domain.consumer.name }
        end
      end
    end
  end
end