require_relative 'base_decorator'
require_relative 'version_decorator'

module PactBroker

  module Api

    module Decorators


      class VersionsDecorator < BaseDecorator

        collection :entries, as: :versions, embedded: true, :extend => PactBroker::Api::Decorators::VersionDecorator

        link :self do | context |
          {
            href: context[:resource_url],
            title: "All versions of the pacticipant #{context[:pacticipant_name]}"
          }
        end

        link :pacticipant do | context |
          {
            href: pacticipant_url(context[:base_url], OpenStruct.new(name: context[:pacticipant_name])),
            title: context[:pacticipant_name]
          }
        end

        links :'versions' do | context |
          represented.collect do | version |
            {
              :href => version_url(context[:base_url], version),
              :title => version.version_and_updated_date
            }
          end
        end

      end
    end
  end
end
