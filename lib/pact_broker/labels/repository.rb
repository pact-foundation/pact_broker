require "pact_broker/domain/label"

module PactBroker
  module Labels
    class Repository
      def create args
        Domain::Label.new(name: args.fetch(:name), pacticipant: args.fetch(:pacticipant)).save
      end

      def find args
        PactBroker::Domain::Label
          .select_all_qualified
          .join(:pacticipants, { id: :pacticipant_id })
          .where(Sequel.name_like(Sequel.qualify("labels", "name"), args.fetch(:label_name)))
          .where(Sequel.name_like(Sequel.qualify("pacticipants", "name"), args.fetch(:pacticipant_name)))
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
