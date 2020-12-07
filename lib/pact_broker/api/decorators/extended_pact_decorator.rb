require 'pact_broker/api/decorators/pact_decorator'

module PactBroker
  module Api
    module Decorators
      # Make a different content type for adding extra information for the UI, as
      # some pact parsing tools blow up when there are unexpected keys :|

      class ExtendedPactDecorator < PactDecorator
        class TagDecorator < BaseDecorator
          property :name
          property :latest, getter: ->(_) { true }

          link :self do | options |
            {
              title: 'Tag',
              name: represented.name,
              href: tag_url(options[:base_url], represented)
            }
          end

          link "pb:latest-pact" do | opts |
            {
              name: "The latest pact with the tag #{represented.name}",
              href: latest_tagged_pact_url(represented.pact, represented.name, opts[:base_url])
            }
          end
        end

        property :content_hash, as: :contract
        collection :head_tags, exec_context: :decorator, as: :tags, embedded: true, extend: TagDecorator

        # TODO rather than remove the contract keys that we added in the super class,
        # it would be better to inherit from a shared super class
        def to_hash(options = {})
          keys_to_remove = represented.content_hash.keys
          super.each_with_object({}) do | (key, value), new_hash |
            new_hash[key] = value unless keys_to_remove.include?(key)
          end
        end

        def head_tags
          represented.head_tag_names.collect do | tag_name |
            OpenStruct.new(name: tag_name, pact: represented, version: represented.consumer_version)
          end
        end
      end
    end
  end
end