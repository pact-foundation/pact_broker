require 'pact_broker/models/tag'

module PactBroker
  module Repositories
    class TagRepository


      def create args
        Models::Tag.new(name: args.fetch(:name), version: args.fetch(:version)).save
      end

      def find args
        PactBroker::Models::Tag
          .select(:tags__name, :tags__version_id, :tags__created_at, :tags__updated_at)
          .join(:versions, {id: :version_id})
          .join(:pacticipants, {pacticipants__id: :versions__pacticipant_id})
          .where(:tags__name => args.fetch(:tag_name))
          .where(:versions__number => args.fetch(:pacticipant_version_number))
          .where(:pacticipants__name => args.fetch(:pacticipant_name))
          .single_record
      end

    end
  end
end