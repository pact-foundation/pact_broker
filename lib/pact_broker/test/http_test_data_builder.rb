require 'faraday'
require 'faraday_middleware'
require 'logger'
require 'erb'
require 'yaml'

module PactBroker
  module Test
    class HttpTestDataBuilder

      attr_reader :client, :last_consumer_name, :last_provider_name, :last_consumer_version_number, :last_provider_version_number, :last_provider_version_tag, :last_provider_version_branch

      def initialize(pact_broker_base_url, auth = {})
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

      def sleep(seconds = 0.5)
        Kernel.sleep(seconds)
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
        client.put("pacticipants/#{encode(pacticipant)}/versions/#{encode(version)}/tags/#{encode(tag)}", {}).tap { |response| check_for_error(response) }
        self
      end

      def create_version(pacticipant:, version:, branch:)
        request_body = {
          branch: branch
        }
        client.put("pacticipants/#{encode(pacticipant)}/versions/#{encode(version)}", request_body).tap { |response| check_for_error(response) }
      end

      def deploy_to_prod(pacticipant:, version:)
        puts "Deploying #{pacticipant} version #{version} to prod"
        create_tag(pacticipant: pacticipant, version: version, tag: "prod")
        separate
        self
      end

      def create_pacticipant(name)
        puts "Creating pacticipant with name #{name}"
        client.post("pacticipants", { name: name}).tap { |response| check_for_error(response) }
        separate
        self
      end

      def publish_pact(consumer: last_consumer_name, consumer_version:, provider: last_provider_name, content_id:, tag: nil, branch:)
        @last_consumer_name = consumer
        @last_provider_name = provider
        @last_consumer_version_number = consumer_version

        create_version(pacticipant: consumer, version: consumer_version, branch: branch) if branch

        [*tag].each do | tag |
          create_tag(pacticipant: consumer, version: consumer_version, tag: tag)
        end
        puts "" if [*tag].any?

        content = generate_content(consumer, provider, content_id)
        puts "Publishing pact for consumer #{consumer} version #{consumer_version} and provider #{provider}"
        pact_path = "pacts/provider/#{encode(provider)}/consumer/#{encode(consumer)}/version/#{encode(consumer_version)}"
        @publish_pact_response = client.put(pact_path, content).tap { |response| check_for_error(response) }
        separate
        self
      end

      def get_pacts_for_verification(provider: last_provider_name, provider_version_tag: nil, provider_version_branch: nil, consumer_version_selectors:, enable_pending: false, include_wip_pacts_since: nil)
        @last_provider_name = provider
        @last_provider_version_tag = provider_version_tag
        @last_provder_version_branch = provider_version_branch
        puts "Fetching pacts for verification for #{provider}"
        request_body = {
          providerVersionTags: [*provider_version_tag],
          providerVersionBranch: provider_version_branch,
          consumerVersionSelectors: consumer_version_selectors,
          includePendingStatus: enable_pending,
          includeWipPactsSince: include_wip_pacts_since
        }.compact
        puts request_body.to_yaml
        puts ""
        @pacts_for_verification_response = client.post("pacts/provider/#{encode(provider)}/for-verification", request_body).tap { |response| check_for_error(response) }

        print_pacts_for_verification
        separate
        self
      end

      def print_pacts_for_verification
        pacts = @pacts_for_verification_response.body&.dig("_embedded", "pacts")
        puts @pacts_for_verification_response.body.to_json
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

      def verify_latest_pact_for_tag(success: true, provider: last_provider_name, consumer: last_consumer_name, consumer_version_tag: , provider_version:, provider_version_tag: nil)
        @last_provider_name = provider
        @last_consumer_name = consumer

        url_of_pact_to_verify = "pacts/provider/#{encode(provider)}/consumer/#{encode(consumer)}/latest/#{encode(consumer_version_tag)}"
        publish_verification_results(url_of_pact_to_verify, provider, provider_version, provider_version_tag, success)
        separate
        self
      end

      def verify_pact(index: 0, success:, provider: last_provider_name, provider_version_tag: last_provider_version_tag, provider_version_branch: last_provider_version_branch, provider_version: )
        @last_provider_name = provider
        @last_provider_version_tag = provider_version_tag
        @last_provider_version_branch = provider_version_branch

        pact_to_verify = @pacts_for_verification_response.body["_embedded"]["pacts"][index]
        raise "No pact found to verify at index #{index}" unless pact_to_verify
        url_of_pact_to_verify = pact_to_verify["_links"]["self"]["href"]

        publish_verification_results(url_of_pact_to_verify, provider, provider_version, provider_version_tag, success)
        separate
        self
      end

      def create_global_webhook_for_contract_changed(uuid: nil, url: "https://postman-echo.com/post")
        puts "Creating global webhook for contract changed event with uuid #{uuid}"
        uuid ||= SecureRandom.uuid
        request_body = {
          "description" => "A webhook for all consumers and providers",
          "events" => [{
            "name" => "contract_content_changed"
          }],
          "request" => {
            "method" => "POST",
            "url" => url
          }
        }
        path = "webhooks/#{uuid}"
        response = client.put(path, request_body.to_json).tap { |response| check_for_error(response) }
        separate
        self
      end

      def create_global_webhook_for_verification_published(uuid: nil, url: "https://postman-echo.com/post")
        puts "Creating global webhook for contract changed event with uuid #{uuid}"
        uuid ||= SecureRandom.uuid
        request_body = {
          "description" => "A webhook for all consumers and providers",
          "events" => [{
            "name" => "contract_published"
          },{
            "name" => "provider_verification_published"
          }],
          "request" => {
            "method" => "POST",
            "url" => url,
            "headers" => { "Content-Type" => "application/json"},
            "body" => {
              "eventName" => "${pactbroker.eventName}",
              "consumerVersionNumber" => "${pactbroker.consumerVersionNumber}",
              "consumerVersionTags" => "${pactbroker.consumerVersionTags}",
              "githubVerificationStatus" => "${pactbroker.githubVerificationStatus}",
              "providerVersionNumber" => "${pactbroker.providerVersionNumber}",
              "providerVersionTags" => "${pactbroker.providerVersionTags}"
            }
          }
        }
        path = "webhooks/#{uuid}"
        response = client.put(path, request_body.to_json).tap { |response| check_for_error(response) }
        separate
        self
      end

      def delete_webhook(uuid:)
        puts "Deleting webhook with uuid #{uuid}"
        path = "webhooks/#{uuid}"
        response = client.delete(path).tap { |response| check_for_error(response) }
        separate
        self
      end

      def print_pacts_for_verification_response
        puts @pacts_for_verification_response.body
        self
      end

      def can_i_deploy(pacticipant:, version:, to:)
        can_i_deploy_response = client.get("can-i-deploy", { pacticipant: pacticipant, version: version, to: to} ).tap { |response| check_for_error(response) }
        can = !!(can_i_deploy_response.body['summary'] || {})['deployable']
        puts "can-i-deploy #{pacticipant} version #{version} to #{to}: #{can ? 'yes' : 'no'}"
        summary = can_i_deploy_response.body['summary']
        verification_result_urls = (can_i_deploy_response.body['matrix'] || []).collect do | row |
          row.dig("verificationResult", "_links", "self", "href")
        end.compact
        summary.merge!("verification_result_urls" => verification_result_urls)
        puts summary.to_yaml
        separate
        self
      end

      def delete_integration(consumer:, provider:)
        puts "Deleting all data for the integration between #{consumer} and #{provider}"
        client.delete("integrations/provider/#{encode(provider)}/consumer/#{encode(consumer)}").tap { |response| check_for_error(response) }
        separate
        self
      end

      def delete_pacticipant(name)
        puts "Deleting pacticipant #{name}"
        @publish_pact_response = client.delete("pacticipants/#{encode(name)}").tap { |response| check_for_error(response) }
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
              description: "a request",
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

      private

      def publish_verification_results(url_of_pact_to_verify, provider, provider_version, provider_version_tag, success)
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