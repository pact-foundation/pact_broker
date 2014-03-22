require 'pact_broker/models'
require 'pact_broker/repositories/pacticipant_repository'
require 'pact_broker/repositories/version_repository'
require 'pact_broker/repositories/pact_repository'
require 'pact_broker/repositories/tag_repository'

module PactBroker
  module Repositories
    def pacticipant_repository
      PacticipantRepository.new
    end

    def version_repository
      VersionRepository.new
    end

    def pact_repository
      PactRepository.new
    end

    def tag_repository
      TagRepository.new
    end

    extend self
  end
end
