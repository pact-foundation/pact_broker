require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/pagination_links"

module PactBroker
  module Api
    module Decorators
      describe BaseDecorator do
        class TestItemDecorator < BaseDecorator
          include PactBroker::Api::Decorators::PaginationLinks

          collection :children
          property :foo, embedded: true

          property :bar do
            property :name
          end

          property :other
        end

        class TestItemsDecorator < BaseDecorator
          collection :entries, as: :items, embedded: true, :extend => TestItemDecorator

          link :self do
            "http://foo"
          end
        end

        describe "eager_load_associations" do
          context "for an individual resource" do
            it "returns the attributes that are collections or embedded" do
              expect(TestItemDecorator.eager_load_associations).to eq [:children, :foo, :bar]
            end
          end

          context "for a collection decorator" do
            it "returns the eager_load_associations of the class used to decorate the collection items" do
              expect(TestItemsDecorator.eager_load_associations).to eq [:children, :foo, :bar]
            end
          end
        end
      end
    end
  end
end
