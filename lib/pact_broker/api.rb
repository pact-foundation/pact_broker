require 'pact_broker/api/resources/pact'
require 'pact_broker/api/resources/latest_pact'
require 'pact_broker/api/resources/latest_pacts'
require 'pact_broker/api/resources/pacticipant'
require 'pact_broker/api/resources/pacticipants'
require 'pact_broker/api/resources/tag'
require 'pact_broker/api/resources/index'
require 'pact_broker/api/resources/relationships'

require 'webmachine/adapters/rack'

module PactBroker

  API ||= begin
    pact_api = Webmachine::Application.new do |app|
      app.routes do
        add(['trace', '*'], Webmachine::Trace::TraceResource) unless ENV['RACK_ENV'] == 'production'
        add ['pact', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number], Api::Resources::Pact
        add ['pact', 'provider', :provider_name, 'consumer', :consumer_name, 'latest'], Api::Resources::LatestPact
        add ['pacts', 'latest'], Api::Resources::LatestPacts
        add ['pacticipants'], Api::Resources::Pacticipants
        add ['pacticipants', :name], Api::Resources::Pacticipant
        add ['pacticipants', :pacticipant_name, 'versions', :pacticipant_version_number, 'tags', :tag_name], Api::Resources::Tag
        add ['relationships'], Api::Resources::Relationships
        add [], Api::Resources::Index
      end
    end

    pact_api.configure do |config|
      config.adapter = :Rack
    end

    pact_api.adapter
  end

end
