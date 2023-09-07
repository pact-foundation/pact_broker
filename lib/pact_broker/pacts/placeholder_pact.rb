require "pact_broker/domain/pact"

module PactBroker
  module Pacts
    class PlaceholderPact < PactBroker::Domain::Pact
      def initialize
        consumer = OpenStruct.new(name: "placeholder-consumer", labels: [OpenStruct.new(name: "placeholder-consumer-label")])
        @provider = OpenStruct.new(name: "placeholder-provider", labels: [OpenStruct.new(name: "placeholder-provider-label")])
        @consumer_version = OpenStruct.new(number: "gggghhhhjjjjkkkkllll66667777888899990000", pacticipant: consumer)
        @consumer_version_number = @consumer_version.number
        @created_at = DateTime.now
        @revision_number = 1
        @pact_version_sha = "5d445a4612743728dfd99ccd4210423c052bb9db"
        @consumer_version_tag_names = ["dev"]
        @consumer_version_branch_names = ["main"]
      end
    end
  end
end
