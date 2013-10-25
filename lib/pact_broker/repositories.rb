require 'pact_broker/models'
require 'pact_broker/repositories/pacticipant_repository'
require 'pact_broker/repositories/version_repository'

module PactBroker
  module Repositories
    def self.included(base)
      base.extend(self)
    end

    def pacticipant_respository
      PactBroker::Repositories::PacticipantRepository.new
    end

    def version_repository
      PactBroker::Repositories::VersionRepository.new
    end
  end

  include Repositories
end
