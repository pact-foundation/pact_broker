require 'pact_broker/domain/tag'
require 'pact_broker/repositories/helpers'


module PactBroker
  module Repositories
    class TagRepository

      include Helpers

      def create args
        Domain::Tag.new(name: args.fetch(:name), version: args.fetch(:version)).save
      end

      def find args
        PactBroker::Domain::Tag
          .select(:tags__name, :tags__version_id, :tags__created_at, :tags__updated_at)
          .join(:versions, {id: :version_id})
          .join(:pacticipants, {pacticipants__id: :versions__pacticipant_id})
          .where(name_like(:tags__name, args.fetch(:tag_name)))
          .where(name_like(:versions__number, args.fetch(:pacticipant_version_number)))
          .where(name_like(:pacticipants__name, args.fetch(:pacticipant_name)))
          .single_record
      end
    end
  end
end
