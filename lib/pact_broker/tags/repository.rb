require "pact_broker/domain/tag"
require "pact_broker/repositories"

module PactBroker
  module Tags
    class Repository
      include PactBroker::Repositories

      def create args
        params = {
          name: args.fetch(:name),
          version_id: args.fetch(:version).id,
          version_order: args.fetch(:version).order,
          pacticipant_id: args.fetch(:version).pacticipant_id
        }
        Domain::Tag.new(params).insert_ignore
      end

      def find args
        PactBroker::Domain::Tag
          .select_all_qualified
          .join(:versions, { id: :version_id })
          .join(:pacticipants, {Sequel.qualify("pacticipants", "id") => Sequel.qualify("versions", "pacticipant_id")})
          .where(Sequel.name_like(Sequel.qualify("tags", "name"), args.fetch(:tag_name)))
          .where(Sequel.name_like(Sequel.qualify("versions", "number"), args.fetch(:pacticipant_version_number)))
          .where(Sequel.name_like(Sequel.qualify("pacticipants", "name"), args.fetch(:pacticipant_name)))
          .single_record
      end

      def delete_by_version_id version_id
        Domain::Tag.where(version_id: version_id).delete
      end

      def find_all_tag_names_for_pacticipant pacticipant_name
        PactBroker::Domain::Tag
        .select(Sequel[:tags][:name])
        .join(:versions, { Sequel[:versions][:id] => Sequel[:tags][:version_id] })
        .join(:pacticipants, { Sequel[:pacticipants][:id] => Sequel[:versions][:pacticipant_id] })
        .where(Sequel[:pacticipants][:name] => pacticipant_name)
        .distinct
        .collect{ |tag| tag[:name] }.sort
      end

      def find_all_by_pacticipant_name_and_tag(pacticipant_name, tag_name)
        pacticipant = pacticipant_repository.find_by_name(pacticipant_name)
        return PactBroker::Domain::Tag.where(pacticipant_id: pacticipant.id, name: tag_name) if pacticipant

        []
      end

    end
  end
end
