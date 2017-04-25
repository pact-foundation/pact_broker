require 'reform'
require 'reform/form/dry'
Reform::Form.class_eval do
  feature Reform::Form::Dry
end

require 'pact_broker/api/resources/pact'
require 'pact_broker/api/resources/latest_pact'
require 'pact_broker/api/resources/latest_pacts'
require 'pact_broker/api/resources/pacticipant'
require 'pact_broker/api/resources/pacticipants'
require 'pact_broker/api/resources/tag'
require 'pact_broker/api/resources/index'
require 'pact_broker/api/resources/relationships'
require 'pact_broker/api/resources/group'
require 'pact_broker/api/resources/pact_webhooks'
require 'pact_broker/api/resources/pact_versions'
require 'pact_broker/api/resources/webhooks'
require 'pact_broker/api/resources/webhook'
require 'pact_broker/api/resources/webhook_execution'
require 'pact_broker/api/resources/version'
require 'pact_broker/api/resources/versions'
require 'pact_broker/api/resources/pact_content_diff'
require 'pact_broker/api/resources/previous_distinct_pact_version'
require 'pact_broker/api/resources/latest_provider_pacts'
require 'pact_broker/api/resources/verifications'
require 'pact_broker/api/resources/latest_verifications_for_consumer_version'

require 'webmachine/adapters/rack_mapped'

module PactBroker

  API ||= begin
    pact_api = Webmachine::Application.new do |app|
      app.routes do
        add(['trace', :*], Webmachine::Trace::TraceResource) unless ENV['RACK_ENV'] == 'production'

        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'versions'], Api::Resources::PactVersions
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'versions', :consumer_version_number], Api::Resources::Pact # Not the standard URL, but keep for backwards compatibility

        # Pacts
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number], Api::Resources::Pact
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number, 'previous-distinct'], Api::Resources::PreviousDistinctPactVersion
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number, 'diff', 'previous-distinct'], Api::Resources::PactContentDiff

        # Verifications
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'pact-version-sha', :pact_version_sha, 'verifications'], Api::Resources::Verifications
        add ['pacts', 'consumer', :consumer_name, 'versions', :consumer_version_number, 'verifications', 'latest'], Api::Resources::LatestVerificationsForConsumerVersion

        # Latest pacts
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'latest'], Api::Resources::LatestPact
        add ['pacts', 'provider', :provider_name, 'consumer', :consumer_name, 'latest', :tag], Api::Resources::LatestPact
        add ['pacts', 'provider', :provider_name, 'latest'], Api::Resources::LatestProviderPacts
        add ['pacts', 'provider', :provider_name, 'latest', :tag], Api::Resources::LatestProviderPacts
        add ['pacts', 'latest'], Api::Resources::LatestPacts

        # Deprecated pact
        add ['pact', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number], Api::Resources::Pact # Deprecate, singular /pact
        add ['pact', 'provider', :provider_name, 'consumer', :consumer_name, 'latest'], Api::Resources::LatestPact

        # Pacticipants
        add ['pacticipants'], Api::Resources::Pacticipants
        add ['pacticipants', :name], Api::Resources::Pacticipant
        add ['pacticipants', :pacticipant_name, 'versions'], Api::Resources::Versions
        add ['pacticipants', :pacticipant_name, 'versions', :pacticipant_version_number], Api::Resources::Version
        add ['pacticipants', :pacticipant_name, 'versions', :pacticipant_version_number, 'tags', :tag_name], Api::Resources::Tag

        # Webhooks
        add ['webhooks', 'provider', :provider_name, 'consumer', :consumer_name ], Api::Resources::PactWebhooks
        add ['webhooks', :uuid ], Api::Resources::Webhook
        add ['webhooks', :uuid, 'execute' ], Api::Resources::WebhookExecution
        add ['webhooks'], Api::Resources::Webhooks

        add ['relationships'], Api::Resources::Relationships
        add ['groups', :pacticipant_name], Api::Resources::Group

        add [], Api::Resources::Index
      end
    end

    pact_api.configure do |config|
      config.adapter = :RackMapped
    end

    pact_api.adapter
  end

end
