require_relative 'base_decorator'
require_relative 'pact_version_decorator'

module PactBroker

  module Api

    module Decorators


      class ProviderPactsDecorator < BaseDecorator

        link :self do | context |
          suffix = context[:tag] ? " with tag '#{context[:tag]}'" : ""
          {
            href: context[:resource_url],
            title: "Latest pact versions for the provider #{context[:provider_name]}#{suffix}"
          }
        end

        link :provider do | context |
          {
            href: pacticipant_url(context[:base_url], OpenStruct.new(name: context[:provider_name])),
            title: context[:provider_name]
          }
        end

        links :'pacts' do | context |
          represented.collect do | pact |
            {
              :href => pact_url(context[:base_url], pact),
              :title => pact.name,
              :name => pact.consumer.name
            }
          end
        end

      end
    end
  end
end
