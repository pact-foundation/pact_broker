
module PactBroker
  module Api
    module Decorators
      class ReleasedVersionsDecorator < BaseDecorator
        collection :entries, as: :releasedVersions, embedded: true, :extend => PactBroker::Api::Decorators::EmbeddedReleasedVersionDecorator

        link :self do | context |
          href = append_query_if_present(context[:resource_url], context[:query_string])
          {
            href: href,
            title: context.fetch(:title)
          }
        end
      end
    end
  end
end
