require 'ostruct'
require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    module Decorators
      class DashboardTextDecorator
        include PactBroker::Api::PactBrokerUrls

        Line = Struct.new(:consumer_name, :c_version, :c_tags , :provider_name, :p_version, :p_tags, :success)

        def initialize(index_items)
          @index_items = index_items
        end

        def to_json(options)
          to_hash(options).to_json
        end

        def to_text(options)
          data = items(index_items, options[:user_options][:base_url])
          printer = TablePrint::Printer.new(data)
          printer.table_print + "\n"
        end

        private

        attr_reader :index_items

        def items(index_items, base_url)
          index_items.collect do | index_item |
            index_item_object(index_item)
          end
        end

        def index_item_object(index_item)
          Line.new(
            index_item.consumer_name,
            index_item.consumer_version_number,
            index_item.tag_names.join(", "),
            index_item.provider_name,
            index_item.provider_version_number,
            index_item.latest_verification_latest_tags.collect(&:name).join(", "),
            index_item.verification_status.to_s
          )
        end
      end
    end
  end
end
