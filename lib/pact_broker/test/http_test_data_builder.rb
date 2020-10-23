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
          faraday.response :logger, ::Logger.new($stdout), headers: false do | logger |
            logger.filter(/(Authorization: ).*/,'\1[REMOVED]')
          end
          # faraday.headers['Authorization'] = "Bearer #{pactflow_api_token}"
          faraday.adapter  Faraday.default_adapter
        end
      end

      def sleep
        Kernel.sleep 1
        self
      end

      def create_tagged_pacticipant_version(pacticipant:, version:, tag:)
        [*tag].each do | tag |
          create_tag(pacticipant: pacticipant, version: version, tag: tag)
        end
        self
      end

      def create_tag(pacticipant:, version:, tag:)
        puts "Creating tag '#{tag}' for #{pacticipant} version #{version}"
        client.put("/pacticipants/#{encode(pacticipant)}/versions/#{encode(version)}/tags/#{encode(tag)}", {})
        self
      end

      def publish_pact(consumer: last_consumer_name, consumer_version:, provider: last_provider_name, content_id:, tag:)
        @last_consumer_name = consumer
        @last_provider_name = provider
        @last_consumer_version_number = consumer_version

        [*tag].each do | tag |
          create_tag(pacticipant: consumer, version: consumer_version, tag: tag)
        end


        content = generate_content(consumer, provider, content_id)
        puts "Publishing pact for consumer #{consumer} version #{consumer_version} and provider #{provider}"
        pact_path = "/pacts/provider/#{encode(provider)}/consumer/#{encode(consumer)}/version/#{encode(consumer_version)}"
        @publish_pact_response = client.put(pact_path, content)
        self
      end

      def get_pacts_for_verification(provider: last_provider_name, provider_version_tag: , consumer_version_selectors:, enable_pending: false, include_wip_pacts_since: nil)
        puts "Fetching pacts for verification for #{provider}"
        body = {
          providerVersionTags: [*provider_version_tag],
          consumerVersionSelectors: consumer_version_selectors,
          includePendingStatus: enable_pending,
          includeWipPactsSince: include_wip_pacts_since
        }
        @pacts_for_verification_response = client.post("/pacts/provider/#{encode(provider)}/for-verification", body)
        self
      end

      def print_pacts_for_verification
        puts "Pacts for verification:"
        @pacts_for_verification_response.body["_embedded"]["pacts"].each do | pact |
          puts({
            "url" => pact["_links"]["self"]["href"],
            "wip" => pact["verificationProperties"]["wip"],
            "pending" => pact["verificationProperties"]["pending"]
          }.to_yaml)
        end
        self
      end

      def print_pacts_for_verification_response
        puts @pacts_for_verification_response.body
        self
      end

      def delete_integration(consumer:, provider:)
        client.delete("/integrations/provider/#{encode(provider)}/consumer/#{encode(consumer)}")
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
    end
  end
end