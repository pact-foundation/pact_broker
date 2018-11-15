require 'sequel'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Pacticipants
    class Repository

      include PactBroker::Repositories::Helpers

      def find_by_name name
        PactBroker::Domain::Pacticipant.where(name_like(:name, name)).single_record
      end

      def find_by_id id
        PactBroker::Domain::Pacticipant.where(id: id).single_record
      end

      def find_all
        find
      end

      def find options = {}
        query = PactBroker::Domain::Pacticipant.select_all_qualified
        query = query.label(options[:label_name]) if options[:label_name]
        query.order_ignore_case(Sequel[:pacticipants][:name]).eager(:labels).eager(:latest_version).all
      end

      def find_all_pacticipant_versions_in_reverse_order name
        PactBroker::Domain::Version.select_all_qualified
          .join(:pacticipants, {id: :pacticipant_id})
          .where(name_like(:name, name))
          .reverse_order(:order)
      end

      def find_by_name_or_create name
        if pacticipant = find_by_name(name)
          pacticipant
        else
          create name: name
        end
      end

      def create args
        PactBroker::Domain::Pacticipant.dataset.insert_ignore.insert(
          name: args[:name],
          repository_url: args[:repository_url],
          created_at: Sequel.datetime_class.now,
          updated_at: Sequel.datetime_class.now
        )
        PactBroker::Domain::Pacticipant.find(name: args[:name])
      end

      def pacticipant_names
        PactBroker::Domain::Pacticipant.select(:name).order(:name).collect{ | pacticipant| pacticipant.name }
      end
    end
  end
end
