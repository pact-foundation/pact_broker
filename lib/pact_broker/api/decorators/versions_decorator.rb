require_relative "base_decorator"
require_relative "version_decorator"
require_relative "pagination_links"

module PactBroker
  module Api
    module Decorators
      class VersionsDecorator < BaseDecorator

        class VersionInCollectionDecorator < PactBroker::Api::Decorators::VersionDecorator

          # VersionDecorator has a dynamic self URL, depending which path the Version resource is mounted at
          # Hardcode the URL of the Versions in the collection to the URL with the number.
          link :self do | user_options |
            {
              title: "Version",
              name: represented.number,
              href: version_url(user_options.fetch(:base_url), represented)
            }
          end
        end

        collection :entries, as: :versions, embedded: true, :extend => VersionInCollectionDecorator

        link :self do | user_options |
          {
            href: user_options.fetch(:request_url),
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
