require_relative "base_decorator"
require_relative "pact_version_decorator"

module PactBroker
  module Api
    module Decorators
      class ProviderPactsDecorator < BaseDecorator

        link :self do | context |
          {
            href: context[:resource_url],
            title: context[:title]
          }
        end

        link :'pb:provider' do | context |
          {
            href: pacticipant_url(context[:base_url], OpenStruct.new(name: context[:provider_name])),
            name: context[:provider_name]
          }
        end

        # TODO make the title and name consistent with title and name of other resources
        links :'pb:pacts' do | context |
          represented.collect do | pact |
            {
              :href => pact_url(context[:base_url], pact),
              :title => pact.name,
              :name => pact.consumer_name
            }
          end
        end

        link :provider do | context |
          {
            href: pacticipant_url(context[:base_url], OpenStruct.new(name: context[:provider_name])),
            title: context[:provider_name],
            name: "DEPRECATED - please use the pb:provider relation"
          }
        end

        links :'pacts' do | context |
          represented.collect do | pact |
            {
              :href => pact_url(context[:base_url], pact),
              :title => "DEPRECATED - please use the pb:pacts relation. #{pact.name}",
              :name => pact.consumer_name
            }
          end
        end
      end
    end
  end
end
