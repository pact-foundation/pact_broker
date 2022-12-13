require "sequel"
require "pact_broker/domain/pacticipant"
require "pact_broker/repositories/helpers"
require "pact_broker/error"

module PactBroker
  module Pacticipants
    class Repository

      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

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

      def find_all(pagination_options = nil)
        find({}, pagination_options)
      end

      def find(options = {}, pagination_options = nil)
        query = PactBroker::Domain::Pacticipant.select_all_qualified
        query = query.label(options[:label_name]) if options[:label_name]
        query.order_ignore_case(Sequel[:pacticipants][:name]).eager(:labels).eager(:latest_version).all_with_pagination_options(pagination_options)
      end

      def find_by_name_or_create name
        pacticipant = find_by_name(name)
        pacticipant ? pacticipant : create(name: name)
      end

      # Need to be able to handle two calls that make the pacticipant at the same time.
      # TODO raise error if attributes apart from name are different, because this indicates that
      # the second request is not at the same time.
      def create params
        PactBroker::Domain::Pacticipant.new(
          name: params.fetch(:name),
          display_name: params[:display_name],
          repository_url: params[:repository_url],
          repository_name: params[:repository_name],
          repository_namespace: params[:repository_namespace],
          main_branch: params[:main_branch]
        ).insert_ignore.refresh
      end

      def update(pacticipant_name, pacticipant)
        pacticipant.name = pacticipant_name
        pacticipant.save.refresh
      end

      def replace(pacticipant_name, open_struct_pacticipant)
        PactBroker::Domain::Pacticipant.new(
          name: pacticipant_name,
          display_name: open_struct_pacticipant.display_name,
          repository_url: open_struct_pacticipant.repository_url,
          repository_name: open_struct_pacticipant.repository_name,
          repository_namespace: open_struct_pacticipant.repository_namespace,
          main_branch: open_struct_pacticipant.main_branch
        ).upsert
      end

      def delete(pacticipant)
        pacticipant.destroy
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

      def search_by_name(pacticipant_name)
        terms = pacticipant_name.split.map { |v| v.gsub("_", "\\_") }
        string_match_query = Sequel.|( *terms.map { |term| Sequel.ilike(Sequel[:pacticipants][:name], "%#{term}%") })
        PactBroker::Domain::Pacticipant.where(string_match_query)
      end

      def set_main_branch(pacticipant, main_branch)
        pacticipant.update(main_branch: main_branch)
      end
    end
  end
end
