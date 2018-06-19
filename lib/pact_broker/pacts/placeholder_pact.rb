require 'pact_broker/domain/pact'

module PactBroker
  module Pacts
    class PlaceholderPact < PactBroker::Domain::Pact
      def initialize
        consumer = OpenStruct.new(name: "placeholder-consumer")
        @provider = OpenStruct.new(name: "placeholder-provider")
        @consumer_version = OpenStruct.new(number: "1", pacticipant: consumer, tags: [OpenStruct.new(name: "master")])
        @consumer_version_number = @consumer_version.number
        @created_at = DateTime.now
        @revision_number = 1
        @pact_version_sha = "5d445a4612743728dfd99ccd4210423c052bb9db"
      end
    end
  end
end
