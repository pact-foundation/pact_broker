require 'csv'

module PactBroker

  module Api

    module Decorators

      class RelationshipsCsvDecorator

        def initialize pacts
          @pacts = pacts
        end

        def to_csv

          CSV.generate do |csv|
            csv << ["source", "target", "weight"]
            pacts.each do | pact |
              csv << [pact.consumer.name, pact.provider.name, 1]
            end
          end
        end

        private

        attr_accessor :pacts

      end
    end
  end
end