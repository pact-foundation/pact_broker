require "pact_broker/domain/verification"

# Represents a non WIP, successful verification for a provider version with a tag.

module PactBroker
  module Verifications
    class PactVersionProviderTagSuccessfulVerification < Sequel::Model
      plugin :insert_ignore, identifying_columns: [:pact_version_id, :provider_version_tag_name, :wip]
    end
  end
end
