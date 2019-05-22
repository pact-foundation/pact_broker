require 'sucker_punch'
require 'faraday'
require 'pact_broker/logging'

module PactBroker
  class VerificationJob
    include SuckerPunch::Job
    include PactBroker::Logging

    def perform data
      pact_url = data.fetch(:pactUrl)
      pact = Faraday.get(pact_url, nil, { 'Accept' => 'application/hal+json'}).body
      pact_hash = JSON.parse(pact)

      headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/hal+json'
      }

      provider_version = "1.2.3"
      provider_url = pact_hash['_links']['pb:provider']['href']
      Faraday.put("#{provider_url}/versions/#{provider_version}/tags/dev", nil, headers)

      verification_url = pact_hash['_links']['pb:publish-verification-results']['href']
      body = {
        success: true,
        providerApplicationVersion: provider_version
      }

      Faraday.post(verification_url, body.to_json, headers)
    end
  end
end
