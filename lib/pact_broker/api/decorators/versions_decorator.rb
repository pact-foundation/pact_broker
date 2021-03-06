require_relative 'base_decorator'
require_relative 'version_decorator'
require_relative 'pagination_links'

module PactBroker
  module Api
    module Decorators
      class VersionsDecorator < BaseDecorator

        collection :entries, as: :versions, embedded: true, :extend => PactBroker::Api::Decorators::VersionDecorator

        link :self do | context |
          href = append_query_if_present(context[:resource_url], context[:query_string])
          {
            href: href,
            title: "All application versions of #{context[:pacticipant_name]}"
          }
        end

        include PaginationLinks

        link :'pb:pacticipant' do | context |
          {
            href: pacticipant_url(context[:base_url], OpenStruct.new(name: context[:pacticipant_name])),
            title: context[:pacticipant_name]
          }
        end

        links :'pb:versions' do | context |
          represented.collect do | version |
            {
              :href => version_url(context[:base_url], version),
              :title => version.version_and_updated_date
            }
          end
        end

        link :pacticipant do | context |
          {
            href: pacticipant_url(context[:base_url], OpenStruct.new(name: context[:pacticipant_name])),
            title: 'Deprecated - please use pb:pacticipant'
          }
        end

        links :'versions' do | context |
          represented.collect do | version |
            {
              :href => version_url(context[:base_url], version),
              :title => 'Deprecated - please use pb:versions'
            }
          end
        end
      end
    end
  end
end
