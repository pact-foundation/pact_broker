require_relative 'base_decorator'
require_relative 'pact_version_decorator'

module PactBroker

  module Api

    module Decorators


      class PactVersionsDecorator < BaseDecorator

        collection :entries, as: :pacts, embedded: true, :extend => PactBroker::Api::Decorators::PactVersionDecorator

        link :self do | context |
          {
            href: context.resource_url,
            title: "All versions of the pact between #{context[:consumer_name]} and #{context[:provider_name]}"
          }
        end

        link :consumer do | context |
          {
            href: pacticipant_url(context.base_url, OpenStruct.new(name: context[:consumer_name])),
            title: context[:consumer_name]
          }
        end

        link :provider do | context |
          {
            href: pacticipant_url(context.base_url, OpenStruct.new(name: context[:provider_name])),
            title: context[:provider_name]
          }
        end

        links :'pact-versions' do | context |
          represented.collect do | pact |
            {
              :href => pact_url(context.base_url, pact),
              :title => pact.version_and_updated_date
            }
          end
        end

      end
    end
  end
end
