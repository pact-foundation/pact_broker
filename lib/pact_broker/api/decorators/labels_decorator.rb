module PactBroker
  module Api
    module Decorators
      class LabelsDecorator < BaseDecorator
        attr_reader :labels

        def initialize(labels)
          @labels = labels
        end

        include PaginationLinks

        def to_hash(opts)
          {
            "_embedded": {
              labels: {
                names: labels
              }
            },
            _links: {
              self: {
                title: "Labels",
                href: opts.fetch(:resource_url)
              }
            }
          }
        end

        def to_json(opts)
          to_hash(opts).to_json
        end
      end
    end
  end
end
