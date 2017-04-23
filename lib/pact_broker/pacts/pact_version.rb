require 'sequel'

module PactBroker
  module Pacts
    class PactVersion < Sequel::Model(:pact_versions)
    end

    PactVersion.plugin :timestamps
  end
end
