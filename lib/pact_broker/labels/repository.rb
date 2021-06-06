require "pact_broker/domain/label"
require "pact_broker/repositories/helpers"

module PactBroker
  module Labels
    class Repository

      include PactBroker::Repositories::Helpers

      def create args
        Domain::Label.new(name: args.fetch(:name), pacticipant: args.fetch(:pacticipant)).save
      end

      def find args
        PactBroker::Domain::Label
          .select(Sequel.qualify("labels", "name"), Sequel.qualify("labels", "pacticipant_id"), Sequel.qualify("labels", "created_at"), Sequel.qualify("labels", "updated_at"))
          .join(:pacticipants, {id: :pacticipant_id})
          .where(name_like(Sequel.qualify("labels", "name"), args.fetch(:label_name)))
          .where(name_like(Sequel.qualify("pacticipants", "name"), args.fetch(:pacticipant_name)))
          .single_record
      end

      def delete args
        find(args).delete
      end

      def delete_by_pacticipant_id pacticipant_id
        Sequel::Model.db[:labels].where(pacticipant_id: pacticipant_id).delete
      end
    end
  end
end
