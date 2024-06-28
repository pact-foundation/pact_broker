require_relative "base_decorator"
require_relative "pagination_links"
require_relative "label_decorator"
require "pact_broker/domain/label"

module PactBroker
  module Api
    module Decorators
      class LabelsDecorator < BaseDecorator
        collection :entries, :as => :labels, :class => PactBroker::Domain::Label, :extend => PactBroker::Api::Decorators::LabelDecorator, embedded: true

        include PaginationLinks

        link :self do | options |
          {
            title: "Labels",
            href: options.fetch(:resource_url)
          }
        end
      end
    end
  end
end
