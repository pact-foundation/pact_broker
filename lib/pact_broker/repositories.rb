require 'pact_broker/models'
require 'pact_broker/repositories/pacticipant_repository'
require 'pact_broker/repositories/version_repository'

module PactBroker
  module Repositories
    def pacticipant_repository
      PacticipantRepository.new
    end

    def version_repository
      VersionRepository.new
    end

    extend self
  end
end
