require 'ostruct'

# TODO remove this class

module PactBroker
  module Api
    module Decorators
      class RepresentablePact

        attr_reader :consumer, :provider, :consumer_version, :consumer_version_number, :created_at, :updated_at

        def initialize pact
          @consumer_version = pact.consumer_version
          @consumer_version_number = pact.consumer_version.number
          @consumer = OpenStruct.new(:version => @consumer_version, :name => pact.consumer.name)
          @provider = OpenStruct.new(:version => nil, :name => pact.provider.name)
          @created_at = pact.created_at
          @updated_at = pact.updated_at
        end

      end
    end
  end
end