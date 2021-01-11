require 'faraday'
require 'faraday_middleware'
require 'logger'
require 'erb'
require 'yaml'

module PactBroker
  module Test
    class HttpTestDataBuilder

      attr_reader :client, :last_consumer_name, :last_provider_name, :last_consumer_version_number, :last_provider_version_number

      def initialize(pact_broker_base_url, auth)
        @client = Faraday.new(url: pact_broker_base_url) do |faraday|
          faraday.request :json
          faraday.response :json, :content_type => /\bjson$/
          if ENV['DEBUG'] == 'true'
            faraday.response :logger, ::Logger.new($stdout), headers: false do | logger |
              logger.filter(/(Authorization: ).*/,'\1[REMOVED]')
            end
          end
          faraday.headers['Authorization'] = "Bearer #{auth[:token]}" if auth[:token]
          faraday.adapter  Faraday.default_adapter
        end
      end

      def sleep
        Kernel.sleep 0.5
        self
      end

      def separate
        puts "\n=============================================================\n\n"
      end

      def create_tagged_pacticipant_version(pacticipant:, version:, tag:)
        [*tag].each do | tag |
          create_tag(pacticipant: pacticipant, version: version, tag: tag)
        end
        self
      end

      def create_tag(pacticipant:, version:, tag:)
        puts "Creating tag '#{tag}' for #{pacticipant} version #{version}"
        client.put("/pacticipants/#{encode(pacticipant)}/versions/#{encode(version)}/tags/#{encode(tag)}", {}).tap { |response| check_for_error(response) }
        self
      end

      def deploy_to_prod(pacticipant:, version:)
        puts "Deploying #{pacticipant} version #{version} to prod"
        create_tag(pacticipant: pacticipant, version: version, tag: "prod")
        separate
        self
      end

      def create_pacticipant(name)
        puts "Creating pacticipant with name #{name}"
        client.post("/pacticipants", { name: name}).tap { |response| check_for_error(response) }
        separate
        self
      end

      def publish_pact(consumer: last_consumer_name, consumer_version:, provider: last_provider_name, content_id:, tag:)
        @last_consumer_name = consumer
        @last_provider_name = provider
        @last_consumer_version_number = consumer_version

        [*tag].each do | tag |
          create_tag(pacticipant: consumer, version: consumer_version, tag: tag)
        end
        puts "" if [*tag].any?

        content = generate_content(consumer, provider, content_id)
        puts "Publishing pact for consumer #{consumer} version #{consumer_version} and provider #{provider}"
        pact_path = "/pacts/provider/#{encode(provider)}/consumer/#{encode(consumer)}/version/#{encode(consumer_version)}"
        @publish_pact_response = client.put(pact_path, content).tap { |response| check_for_error(response) }
        separate
        self
      end

      def get_pacts_for_verification(provider: last_provider_name, provider_version_tag: , consumer_version_selectors:, enable_pending: false, include_wip_pacts_since: nil)
        @last_provider_name = provider
        puts "Fetching pacts for verification for #{provider}"
        body = {
          providerVersionTags: [*provider_version_tag],
          consumerVersionSelectors: consumer_version_selectors,
          includePendingStatus: enable_pending,
          includeWipPactsSince: include_wip_pacts_since
        }.compact
        puts body.to_yaml
        puts ""
        @pacts_for_verification_response = client.post("/pacts/provider/#{encode(provider)}/for-verification", body).tap { |response| check_for_error(response) }

        print_pacts_for_verification
        separate
        self
      end

      def print_pacts_for_verification
        pacts = @pacts_for_verification_response.body&.dig("_embedded", "pacts")
        if pacts
          puts "Pacts for verification (#{pacts.count}):"
          pacts.each do | pact |
            puts({
              "url" => pact["_links"]["self"]["href"],
              "wip" => pact["verificationProperties"]["wip"],
              "pending" => pact["verificationProperties"]["pending"]
            }.to_yaml)
          end
        end
        self
      end

      def verify_pact(index: 0, success:, provider: last_provider_name, provider_version_tag: , provider_version: )
        @last_provider_name = provider
        pact_to_verify = @pacts_for_verification_response.body["_embedded"]["pacts"][index]
        raise "No pact found to verify at index #{index}" unless pact_to_verify
        url_of_pact_to_verify = pact_to_verify["_links"]["self"]["href"]

        [*provider_version_tag].each do | tag |
          create_tag(pacticipant: provider, version: provider_version, tag: tag)
        end
        puts "" if [*provider_version_tag].any?

        pact_response = client.get(url_of_pact_to_verify).tap { |response| check_for_error(response) }
        verification_results_url = pact_response.body["_links"]["pb:publish-verification-results"]["href"]

        results = {
          success: success,
          testResults: [],
          providerApplicationVersion: provider_version
        }
        puts "Publishing verification"
        puts results.to_yaml
        response = client.post(verification_results_url, results.to_json).tap { |response| check_for_error(response) }
        separate
        self
      end

      def print_pacts_for_verification_response
        puts @pacts_for_verification_response.body
        self
      end

      def can_i_deploy(pacticipant:, version:, to:)
        can_i_deploy_response = client.get("/can-i-deploy", { pacticipant: pacticipant, version: version, to: to} ).tap { |response| check_for_error(response) }
        can = !!(can_i_deploy_response.body['summary'] || {})['deployable']
        puts "can-i-deploy #{pacticipant} version #{version} to #{to}: #{can ? 'yes' : 'no'}"
        puts (can_i_deploy_response.body['summary'] || can_i_deploy_response.body).to_yaml
        separate
        self
      end

      def delete_integration(consumer:, provider:)
        puts "Deleting all data for the integration between #{consumer} and #{provider}"
        client.delete("/integrations/provider/#{encode(provider)}/consumer/#{encode(consumer)}").tap { |response| check_for_error(response) }
        separate
        self
      end

      def delete_pacticipant(name)
        puts "Deleting pacticipant #{name}"
        @publish_pact_response = client.delete("/pacticipants/#{encode(name)}").tap { |response| check_for_error(response) }
        separate
        self
      end

      def generate_content(consumer_name, provider_name, content_id)
        {
          consumer: {
            name: consumer_name
          },
          provider: {
            name: provider_name
          },
          interactions: [
            {
              request: {
                method: "GET",
                path: "/things/#{content_id}"
              },
              response: {
                status: 200
              }
            }
          ]
        }
      end

      def encode string
        ERB::Util.url_encode(string)
      end

      def check_for_error(response)
        if ! response.success?
          puts response.status
          puts response.body
        end
      end
    end
  end
end