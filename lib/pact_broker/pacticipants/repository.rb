require 'sequel'
require 'pact_broker/domain/pacticipant'
require 'pact_broker/repositories/helpers'
require 'pact_broker/error'

module PactBroker
  module Pacticipants
    class Repository

      include PactBroker::Repositories::Helpers

      def find_by_name name
        pacticipants = PactBroker::Domain::Pacticipant.where(name_like(:name, name)).all
        handle_multiple_pacticipants_found(name, pacticipants) if pacticipants.size > 1
        pacticipants.first
      end

      def find_by_name! name
        pacticipant = find_by_name(name)
        raise PactBroker::Error, "No pacticipant found with name '#{name}'" unless pacticipant
        pacticipant
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

      # Need to be able to handle two calls that make the pacticipant at the same time.
      # TODO raise error if attributes apart from name are different, because this indicates that
      # the second request is not at the same time.
      def create args
        PactBroker::Domain::Pacticipant.new(
          name: args[:name],
          repository_url: args[:repository_url],
          created_at: Sequel.datetime_class.now,
          updated_at: Sequel.datetime_class.now
        ).insert_ignore
        PactBroker::Domain::Pacticipant.find(name: args[:name])
      end

      def pacticipant_names
        PactBroker::Domain::Pacticipant.select(:name).order(:name).collect(&:name)
      end

      def delete_if_orphan(pacticipant)
        if PactBroker::Domain::Version.where(pacticipant: pacticipant).empty? &&
          PactBroker::Pacts::PactPublication.where(provider: pacticipant).or(consumer: pacticipant).empty? &&
            PactBroker::Pacts::PactVersion.where(provider: pacticipant).or(consumer: pacticipant).empty? &&
            PactBroker::Webhooks::Webhook.where(provider: pacticipant).or(consumer: pacticipant).empty?
          pacticipant.destroy
        end
      end

      def handle_multiple_pacticipants_found(name, pacticipants)
        names = pacticipants.collect(&:name).join(", ")
        raise PactBroker::Error.new("Found multiple pacticipants with a case insensitive name match for '#{name}': #{names}. Please delete one of them, or set PactBroker.configuration.use_case_sensitive_resource_names = true")
      end
    end
  end
end
