require_relative "base_decorator"
require_relative "version_decorator"
require_relative "pagination_links"

module PactBroker
  module Api
    module Decorators
      class VersionsDecorator < BaseDecorator

        collection :entries, as: :versions, embedded: true, :extend => PactBroker::Api::Decorators::VersionDecorator

        link :self do | user_options |
          href = append_query_if_present(user_options[:resource_url], user_options[:query_string])
          {
            href: href,
            title: user_options[:resource_title] || "All application versions of #{user_options[:pacticipant_name]}"
          }
        end

        include PaginationLinks

        link :'pb:pacticipant' do | user_options |
          {
            href: pacticipant_url(user_options[:base_url], OpenStruct.new(name: user_options[:pacticipant_name])),
            title: user_options[:pacticipant_name]
          }
        end

        links :'pb:versions' do | user_options |
          represented.collect do | version |
            {
              :href => version_url(user_options[:base_url], version),
              :title => version.version_and_updated_date
            }
          end
        end

        link :pacticipant do | user_options |
          {
            href: pacticipant_url(user_options[:base_url], OpenStruct.new(name: user_options[:pacticipant_name])),
            title: "Deprecated - please use pb:pacticipant"
          }
        end

        links :'versions' do | user_options |
          represented.collect do | version |
            {
              :href => version_url(user_options[:base_url], version),
              :title => "Deprecated - please use pb:versions"
            }
          end
        end
      end
    end
  end
end
