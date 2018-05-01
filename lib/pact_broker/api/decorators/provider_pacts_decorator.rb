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
            title: context[:title]
          }
        end

        link :provider do | context |
          {
            href: pacticipant_url(context[:base_url], OpenStruct.new(name: context[:provider_name])),
            title: context[:provider_name]
          }
        end

        links :'pb:pacts' do | context |
          represented.collect do | pact |
            {
              :href => pact_url(context[:base_url], pact),
              :title => pact.name,
              :name => pact.consumer_name
            }
          end
        end

        links :'pacts' do | context |
          represented.collect do | pact |
            {
              :href => pact_url(context[:base_url], pact),
              :title => 'DEPRECATED - please use the pb:pacts relation',
              :name => pact.consumer_name
            }
          end
        end
      end
    end
  end
end
