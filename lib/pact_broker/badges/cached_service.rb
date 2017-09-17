require 'pact_broker/logging'
require 'pact_broker/badges/service'

module PactBroker
  module Badges
    module CachedService

      extend self
      include PactBroker::Logging
      extend PactBroker::Services

      CACHE = {}
      private_constant :CACHE

      def pact_verification_badge pact, label, initials, verification_status
        badge_key = key(pact, label, initials, verification_status)
        CACHE[badge_key] ||= PactBroker::Badges::Service.pact_verification_badge(pact, label, initials, verification_status)
      end

      private

      def key pact, label, initials, verification_status
        "#{pact.consumer.name}-#{pact.provider.name}-#{label}-#{initials}-#{verification_status}"
      end
    end
  end
end
