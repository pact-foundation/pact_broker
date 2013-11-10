require 'pact_broker/resources/pact'
require 'pact_broker/resources/latest_pact'
require 'pact_broker/resources/latest_pacts'
require 'pact_broker/resources/pacticipant'
require 'pact_broker/resources/pacticipants'

require 'webmachine/adapters/rack'

module PactBroker

  API ||= begin
    pact_api = Webmachine::Application.new do |app|
      app.routes do
        add(['trace', '*'], Webmachine::Trace::TraceResource) unless ENV['RACK_ENV'] == 'production'
        add ['pact', 'provider', :provider_name, 'consumer', :consumer_name, 'version', :consumer_version_number], Resources::Pact
        add ['pact', 'provider', :provider_name, 'consumer', :consumer_name, 'latest'], Resources::LatestPact
        add ['pacts', 'latest'], Resources::LatestPacts
        add ['pacticipants'], Resources::Pacticipants
        add ['pacticipants', :name], Resources::Pacticipant
      end
    end

    pact_api.configure do |config|
      config.adapter = :Rack
    end

    pact_api.adapter
  end

end
