require "pact_broker/repositories"
require "pact_broker/configuration"
require "pact_broker/logging"

module PactBroker
  module Tags
    module Service
      extend self
      extend PactBroker::Repositories
      include PactBroker::Logging

      def create args
        tag_name = args.fetch(:tag_name)
        pacticipant = pacticipant_repository.find_by_name_or_create args.fetch(:pacticipant_name)
        version = version_repository.find_by_pacticipant_id_and_number_or_create pacticipant.id, args.fetch(:pacticipant_version_number)
        if use_tag_as_branch?(version) && !version.branch
          logger.info "Setting #{version.pacticipant.name} version #{version.number} branch to '#{tag_name}' from first tag (because use_first_tag_as_branch=true)"
          version_repository.set_branch_if_unset(version, tag_name)
        end
        tag_repository.create version: version, name: tag_name
      end

      def find args
        tag_repository.find args
      end

      def delete args
        version = version_repository.find_by_pacticipant_name_and_number args.fetch(:pacticipant_name), args.fetch(:pacticipant_version_number)
        connection = PactBroker::Domain::Tag.new.db
        connection.run("delete from tags where name = '#{args.fetch(:tag_name)}' and version_id = '#{version.id}'")
      end

      def find_all_tag_names_for_pacticipant pacticipant_name
        tag_repository.find_all_tag_names_for_pacticipant pacticipant_name
      end

      def use_tag_as_branch?(version)
        version.tags.count == 0 &&
          PactBroker.configuration.use_first_tag_as_branch &&
          ((now - version.created_at.to_datetime) * 24 * 60 * 60) <= PactBroker.configuration.use_first_tag_as_branch_time_limit
      end

      def now
        Time.now.utc.to_datetime
      end
    end
  end
end
