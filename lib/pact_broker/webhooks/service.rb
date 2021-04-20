require 'pact_broker/repositories'
require 'pact_broker/services'
require 'pact_broker/logging'
require 'base64'
require 'securerandom'
require 'pact_broker/webhooks/job'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/status'
require 'pact_broker/webhooks/webhook_event'
require 'pact_broker/verifications/placeholder_verification'
require 'pact_broker/pacts/placeholder_pact'
require 'pact_broker/api/decorators/webhook_decorator'
require 'pact_broker/hash_refinements'
require 'pact_broker/webhooks/execution_configuration'
require 'pact_broker/messages'
require 'pact_broker/webhooks/pact_and_verification_parameters'
require 'pact_broker/feature_toggle'

module PactBroker
  module Webhooks
    class Service
      using PactBroker::HashRefinements

      RESOURCE_CREATION = PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_RESOURCE_CREATION
      USER = PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_USER

      extend Repositories
      extend Services
      include Logging
      extend PactBroker::Messages

      # Not actually a UUID. Ah well.
      def self.valid_uuid_format?(uuid)
        !!(uuid =~ /^[A-Za-z0-9_\-]{16,}$/)
      end

      def self.next_uuid
        SecureRandom.urlsafe_base64
      end

      def self.errors webhook, uuid = nil
        contract = PactBroker::Api::Contracts::WebhookContract.new(webhook)
        contract.validate(webhook.attributes)
        messages = contract.errors.messages

        if uuid && !valid_uuid_format?(uuid)
          messages["uuid"] = [message("errors.validation.invalid_webhook_uuid")]
        end

        OpenStruct.new(messages: messages, empty?: messages.empty?, any?: messages.any?)
      end

      def self.create uuid, webhook, consumer, provider
        webhook_repository.create uuid, webhook, consumer, provider
      end

      def self.find_by_uuid uuid
        webhook_repository.find_by_uuid uuid
      end

      def self.update_by_uuid uuid, params
        webhook = webhook_repository.find_by_uuid(uuid)
        maintain_redacted_params(webhook, params)
        PactBroker::Api::Decorators::WebhookDecorator.new(webhook).from_hash(params)
        webhook_repository.update_by_uuid uuid, webhook
      end

      def self.delete_by_uuid uuid
        webhook_repository.delete_triggered_webhooks_by_webhook_uuid uuid
        webhook_repository.delete_by_uuid uuid
      end

      def self.delete_all_webhhook_related_objects_by_pacticipant pacticipant
        webhook_repository.delete_executions_by_pacticipant pacticipant
        webhook_repository.delete_triggered_webhooks_by_pacticipant pacticipant
        webhook_repository.delete_by_pacticipant pacticipant
      end

      def self.delete_all_webhook_related_objects_by_pact_publication_ids pact_publication_ids
        webhook_repository.delete_triggered_webhooks_by_pact_publication_ids pact_publication_ids
      end

      def self.delete_all_webhook_related_objects_by_verification_ids verification_ids
        webhook_repository.delete_triggered_webhooks_by_verification_ids verification_ids
      end

      def self.find_all
        webhook_repository.find_all
      end

      def self.test_execution webhook, event_context, execution_configuration
        merged_options = execution_configuration.with_failure_log_message("Webhook execution failed").to_hash

        verification = nil
        if webhook.trigger_on_provider_verification_published?
          verification = verification_service.search_for_latest(webhook.consumer_name, webhook.provider_name) || PactBroker::Verifications::PlaceholderVerification.new
        end

        pact = pact_service.search_for_latest_pact(consumer_name: webhook.consumer_name, provider_name: webhook.provider_name) || PactBroker::Pacts::PlaceholderPact.new
        webhook.execute(pact, verification, event_context.merge(event_name: "test"), merged_options)
      end

      def self.execute_triggered_webhook_now triggered_webhook, webhook_execution_configuration_hash
        webhook_execution_result = triggered_webhook.execute webhook_execution_configuration_hash
        webhook_repository.create_execution triggered_webhook, webhook_execution_result
        webhook_execution_result
      end

      def self.update_triggered_webhook_status triggered_webhook, status
        webhook_repository.update_triggered_webhook_status triggered_webhook, status
      end

      def self.find_for_pact pact
        webhook_repository.find_for_pact(pact)
      end

      def self.find_by_consumer_and_or_provider consumer, provider
        webhook_repository.find_by_consumer_and_or_provider(consumer, provider)
      end

      def self.find_by_consumer_and_provider consumer, provider
        webhook_repository.find_by_consumer_and_provider consumer, provider
      end

      # this method is a mess.
      def self.trigger_webhooks pact, verification, event_name, event_context, options
        webhooks = webhook_repository.find_by_consumer_and_or_provider_and_event_name pact.consumer, pact.provider, event_name

        matching_webhooks = filter_webhooks(webhooks, pact)

        if webhooks.any?
          if matching_webhooks.any?
            webhook_execution_configuration = options.fetch(:webhook_execution_configuration).with_webhook_context(event_name: event_name)
            # bit messy to merge in base_url here, but easier than a big refactor
            base_url = options.fetch(:webhook_execution_configuration).webhook_context.fetch(:base_url)

            run_webhooks_later(matching_webhooks, pact, verification, event_name, event_context.merge(event_name: event_name, base_url: base_url), options.merge(webhook_execution_configuration: webhook_execution_configuration))
          else
            logger.info "No enabled webhooks found for consumer \"#{pact.consumer.name}\" and provider \"#{pact.provider.name}\" and event #{event_name} that match the webhook's consumer version matchers"
          end
        else
          logger.info "No enabled webhooks found for consumer \"#{pact.consumer.name}\" and provider \"#{pact.provider.name}\" and event #{event_name}"
        end
      end

      def self.run_webhooks_later webhooks, pact, verification, event_name, event_context, options
        webhooks.each do | webhook |
          if PactBroker.feature_enabled?(:expand_currently_deployed_provider_versions) && webhook.expand_currently_deployed_provider_versions?
            deployed_version_service.find_currently_deployed_versions_for_pacticipant(pact.provider).collect(&:version_number).uniq.each_with_index do | version_number, index |
              schedule_webhook(webhook, pact, verification, event_name, event_context.merge(currently_deployed_provider_version_number: version_number), options, index * 5)
            end
          else
            schedule_webhook(webhook, pact, verification, event_name, event_context, options)
          end
        end
      end

      def self.schedule_webhook(webhook, pact, verification, event_name, event_context, options, extra_delay = 0)
        begin
          trigger_uuid = next_uuid
          triggered_webhook = webhook_repository.create_triggered_webhook(trigger_uuid, webhook, pact, verification, RESOURCE_CREATION, event_name, event_context)
          logger.info "Scheduling job for webhook with uuid #{webhook.uuid}, context: #{event_context}"
          logger.debug "Schedule webhook with options #{options}"
          job_data = { triggered_webhook: triggered_webhook }.deep_merge(options)
          # Delay slightly to make sure the request transaction has finished before we execute the webhook
          Job.perform_in(5 + extra_delay, job_data)
        rescue StandardError => e
          logger.warn("Error scheduling webhook execution for webhook with uuid #{webhook.uuid}", e)
        end
      end

      def self.find_latest_triggered_webhooks_for_pact pact
        webhook_repository.find_latest_triggered_webhooks_for_pact pact
      end

      def self.find_latest_triggered_webhooks consumer, provider
        webhook_repository.find_latest_triggered_webhooks consumer, provider
      end

      def self.fail_retrying_triggered_webhooks
        webhook_repository.fail_retrying_triggered_webhooks
      end

      def self.find_triggered_webhooks_for_pact pact
        webhook_repository.find_triggered_webhooks_for_pact(pact)
      end

      def self.find_triggered_webhooks_for_verification verification
        webhook_repository.find_triggered_webhooks_for_verification(verification)
      end

      def self.parameters
        PactAndVerificationParameters::ALL.collect do | parameter |
          OpenStruct.new(
            name: parameter,
            description: message("messages.webhooks.parameters.#{parameter}")
          )
        end
      end

      private

      def self.filter_webhooks(webhooks, pact)
        # The consumer_version on the pact domain object is an OpenStruct - need to get the domain object
        consumer_version = PactBroker::Domain::Version.for(pact.consumer.name, pact.consumer_version.number)
        webhooks.select do | webhook |
          webhook.version_matches_consumer_version_matchers?(consumer_version)
        end
      end

      # Dirty hack to maintain existing password or Authorization header if it is submitted with value ****
      # This is required because the password and Authorization header is **** out in the API response
      # for security purposes, so it would need to be re-entered with every response.
      # TODO implement proper 'secrets' management.
      def self.maintain_redacted_params(webhook, params)
        if webhook.request.password && password_key_does_not_exist_or_is_starred?(params)
          params['request']['password'] = webhook.request.password
        end

        new_headers = params['request']['headers'] ||= {}
        existing_headers = webhook.request.headers
        starred_new_headers = new_headers.select { |key, value| value =~ /^\**$/ }
        starred_new_headers.each do | (key, value) |
          new_headers[key] = existing_headers[key]
        end
        params['request']['headers'] = new_headers
        params
      end

      def self.password_key_does_not_exist_or_is_starred?(params)
        !params['request'].key?('password') || params.dig('request','password') =~ /^\**$/
      end
    end
  end
end
