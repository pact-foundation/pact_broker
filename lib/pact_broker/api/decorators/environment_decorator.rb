require_relative 'base_decorator'
require_relative 'timestamps'

module PactBroker
  module Api
    module Decorators
      class EnvironmentDecorator < BaseDecorator
        property :uuid, writeable: false
        property :name
        property :display_name, camelize: true
        property :production

        collection :contacts, class: OpenStruct do
          property :name
          property :details
        end

        include Timestamps

        link :'pb:currently-deployed-versions-for-pacticipant' do | options |
          {
            title: "Currently deployed versions for pacticipant",
            href: "#{environment_url(represented, options[:base_url])}/currently-deployed-versions/pacticipant/{pacticipant}"
          }
        end

        link :self do | options |
          {
            title: 'Environment',
            name: represented.name,
            href: environment_url(represented, options[:base_url])
          }
        end
      end
    end
  end
end
