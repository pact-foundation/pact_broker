require 'ostruct'

module PactBroker
  module Api
    module Decorators
      class RepresentablePact

        attr_reader :consumer, :provider, :consumer_version

        def initialize pact
          @consumer_version = pact.consumer_version
          @consumer = OpenStruct.new(:version => @consumer_version, :name => pact.consumer.name)
          @provider = OpenStruct.new(:version => nil, :name => pact.provider.name)
        end

      end
    end
  end
end