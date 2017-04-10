require 'sequel'
require 'pact_broker/domain/version'
require 'pact_broker/tags/repository'

module PactBroker
  module Verifications
    class Repository

      include PactBroker::Repositories::Helpers

      def verification_count_for_pact pact

      end

    end
  end
end