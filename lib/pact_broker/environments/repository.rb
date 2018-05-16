require 'pact_broker/environments/version_environment'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Environments
    class Repository

      include PactBroker::Repositories::Helpers

      def create args
        VersionEnvironment.new(name: args.fetch(:name), version: args.fetch(:version)).save
      end

      def find args
        VersionEnvironment
          .select_all_qualified
          .join(:versions, { id: :version_id })
          .join(:pacticipants, {Sequel.qualify("pacticipants", "id") => Sequel.qualify("versions", "pacticipant_id")})
          .where(name_like(Sequel.qualify("version_environments", "name"), args.fetch(:environment_name)))
          .where(name_like(Sequel.qualify("versions", "number"), args.fetch(:pacticipant_version_number)))
          .where(name_like(Sequel.qualify("pacticipants", "name"), args.fetch(:pacticipant_name)))
          .single_record
      end

      def delete_by_version_id version_id
        VersionEnvironment.where(version_id: version_id).delete
      end

      def find_all_environment_names_for_pacticipant pacticipant_name
        VersionEnvironment
        .select(Sequel[:version_environments][:name])
        .join(:versions, { Sequel[:versions][:id] => Sequel[:version_environments][:version_id] })
        .join(:pacticipants, { Sequel[:pacticipants][:id] => Sequel[:versions][:pacticipant_id] })
        .where(Sequel[:pacticipants][:name] => pacticipant_name)
        .distinct
        .collect{ |environment| environment[:name] }.sort
      end
    end
  end
end
