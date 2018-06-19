module PactBroker
  module Verifications
    class PlaceholderVerification
      attr_accessor :id, :number, :success,
        :consumer_name, :provider_name, :provider_version,
        :provider_version_number, :build_url,
        :execution_date, :created_at, :pact_version_sha

      def initialize
        @provider_name = "placeholder-provider"
        @consumer_name = "placeholder-consumer"
        @number = 1
        @success = true
        @pact_version_sha = "5d445a4612743728dfd99ccd4210423c052bb9db"
        tags = [OpenStruct.new(name: "master")]
        @provider_version = OpenStruct.new(number: "aaaabbbbccccddddeeeeffff1111222233334444", tags: tags)
        @provider_version_number = @provider_version.number
        @execution_date = DateTime.now
        @created_at = DateTime.now
      end
    end
  end
end
