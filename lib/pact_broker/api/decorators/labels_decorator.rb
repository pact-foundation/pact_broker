require_relative "base_decorator"
require_relative "pagination_links"
require_relative "single_label_decorator"
require "pact_broker/domain/label"

module PactBroker
  module Api
    module Decorators
      class LabelsDecorator < BaseDecorator
        collection :entries, :as => :labels, :class => PactBroker::Domain::Label, :extend => PactBroker::Api::Decorators::SingleLabelDecorator, embedded: true

        include PaginationLinks
      end
    end
  end
end
