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

        link :self do | options |
          {
            title: 'Environment',
            name: represented.name,
            href: environment_url(represented, options[:base_url])
          }
        end

        link :'pb:environments' do | user_options |
          {
            title: "Environments",
            href: environments_url(user_options.fetch(:base_url))
          }
        end
      end
    end
  end
end
