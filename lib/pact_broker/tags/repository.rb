require 'pact_broker/domain/tag'
require 'pact_broker/repositories/helpers'


module PactBroker
  module Tags
    class Repository

      include PactBroker::Repositories::Helpers

      def create args
        Domain::Tag.new(name: args.fetch(:name), version: args.fetch(:version)).save
      end

      def find args
        PactBroker::Domain::Tag
          .select(Sequel.qualify("tags", "name"), Sequel.qualify("tags", "version_id"), Sequel.qualify("tags", "created_at"), Sequel.qualify("tags", "updated_at"))
          .join(:versions, {id: :version_id})
          .join(:pacticipants, {Sequel.qualify("pacticipants", "id") => Sequel.qualify("versions", "pacticipant_id")})
          .where(name_like(Sequel.qualify("tags", "name"), args.fetch(:tag_name)))
          .where(name_like(Sequel.qualify("versions", "number"), args.fetch(:pacticipant_version_number)))
          .where(name_like(Sequel.qualify("pacticipants", "name"), args.fetch(:pacticipant_name)))
          .single_record
      end
    end
  end
end
