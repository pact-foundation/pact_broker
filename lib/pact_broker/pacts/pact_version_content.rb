require 'sequel'

module PactBroker
  module Pacts
    class PactVersionContent < Sequel::Model(:pact_version_contents)
    end

    PactVersionContent.plugin :timestamps
  end
end
