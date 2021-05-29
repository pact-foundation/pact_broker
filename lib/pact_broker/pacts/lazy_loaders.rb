module PactBroker
  module Pacts
    module LazyLoaders
      HEAD_PACT_PUBLICATIONS_FOR_TAGS = lambda {
          consumer_version_tag_names = PactBroker::Domain::Tag.select(:name).where(version_id: consumer_version_id)
          PactPublication
            .for_consumer(consumer)
            .for_provider(provider)
            .latest_for_consumer_tag(consumer_version_tag_names)
            .from_self.order_by(:tag_name)
      }
    end
  end
end
