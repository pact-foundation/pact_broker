require "faraday"
require "logger"
require "erb"
require "yaml"
require "base64"

module PactBroker
  module Test
    class HttpTestDataBuilder

      attr_reader :client, :last_consumer_name, :last_provider_name, :last_consumer_version_number, :last_provider_version_number, :last_provider_version_tag, :last_provider_version_branch

      def initialize(pact_broker_base_url, auth = {})
        @client = Faraday.new(url: pact_broker_base_url) do |faraday|
          faraday.request :json
          faraday.response :json, :content_type => /\bjson$/
          if ENV["DEBUG"] == "true"
            faraday.response :logger, ::Logger.new($stdout), headers: false, body: true do | logger |
              logger.filter(/(Authorization: ).*/,'\1[REMOVED]')
            end
          end
          faraday.basic_auth(auth[:username], auth[:password]) if auth[:username]
          faraday.headers["Authorization"] = "Bearer #{auth[:token]}" if auth[:token]
          faraday.adapter Faraday.default_adapter
        end
      end

      def sleep(seconds = 0.5)
        Kernel.sleep(seconds)
        self
      end

      def separate
        puts "\n=============================================================\n\n"
      end

      def comment string
        puts "**********************************************************"
        puts string
        puts "**********************************************************\n\n"
        self
      end

      def create_tagged_pacticipant_version(pacticipant:, version:, tag:)
        [*tag].each do | t |
          create_tag(pacticipant: pacticipant, version: version, tag: t)
        end
        self
      end

      def create_tag(pacticipant:, version:, tag:)
        puts "Creating tag '#{tag}' for #{pacticipant} version #{version}"
        client.put("pacticipants/#{encode(pacticipant)}/versions/#{encode(version)}/tags/#{encode(tag)}", {}).tap { |response| check_for_error(response) }
        self
      end

      def create_version(pacticipant:, version:, branch: nil)
        if branch
          puts "Adding #{pacticipant} version #{version} to branch #{branch}"
          puts ""
          client.put("pacticipants/#{encode(pacticipant)}/branches/#{encode(branch)}/versions/#{encode(version)}", {}).tap { |response| check_for_error(response) }
        else
          client.put("pacticipants/#{encode(pacticipant)}/versions/#{encode(version)}").tap { |response| check_for_error(response) }
        end
        self
      end

      def deploy_to_prod(pacticipant:, version:)
        puts "Deploying #{pacticipant} version #{version} to prod"
        create_tag(pacticipant: pacticipant, version: version, tag: "prod")
        separate
        self
      end

      def record_deployment(pacticipant:, version:, environment_name:)
        puts "Recording deployment of #{pacticipant} version #{version} to #{environment_name}"
        version_body = client.get("/pacticipants/#{encode(pacticipant)}/versions/#{encode(version)}").tap { |response| check_for_error(response) }.body

        environment_relation = version_body["_links"]["pb:record-deployment"].find { |relation| relation["name"] == environment_name }
        if environment_relation.nil?
          available_environments = version_body["_links"]["pb:record-deployment"].collect{ | relation | relation["name"]}.join
          puts "Environment with name #{environment_name} not found. Available environments: #{available_environments}"
        else
          client.post(environment_relation["href"]).tap { |response| check_for_error(response) }
        end

        separate
        self
      end

      def record_release(pacticipant:, version:, environment_name:)
        puts "Recording release of #{pacticipant} version #{version} to #{environment_name}"
        version_body = client.get("/pacticipants/#{encode(pacticipant)}/versions/#{encode(version)}").tap { |response| check_for_error(response) }.body
        environment_relation = version_body["_links"]["pb:record-release"].find { |relation| relation["name"] == environment_name }
        client.post(environment_relation["href"]).tap { |response| check_for_error(response) }
        separate
        self
      end

      def create_environment(name:, production: false)
        puts "Creating environment #{name}"
        client.post("/environments", { name: name, displayName: name, production: production }).tap { |response| check_for_error(response) }
        separate
        self
      end

      def create_pacticipant(name, main_branch: nil)
        puts "Creating pacticipant with name #{name}"
        client.post("pacticipants", { name: name, mainBranch: main_branch }).tap { |response| check_for_error(response) }
        separate
        self
      end

      def create_label(name, label)
        puts "Creating label '#{label}' for #{name}"
        client.put("pacticipants/#{encode(name)}/labels/#{encode(label)}", {}).tap { |response| check_for_error(response) }
        separate
        self
      end

      def publish_contract(consumer: last_consumer_name, consumer_version:, provider: last_provider_name, content_id:, tag: nil, branch: nil)
        content = generate_content(consumer, provider, content_id)
        request_body_hash = {
          :pacticipantName => consumer,
          :pacticipantVersionNumber => consumer_version,
          :branch => branch,
          :tags => tag ? [tag] : nil,
          :contracts => [
            {
              :consumerName => consumer,
              :providerName => provider,
              :specification => "pact",
              :contentType => "application/json",
              :content => Base64.strict_encode64(content.to_json)
            }
          ]
        }.compact
        response = client.post("contracts/publish", request_body_hash).tap { |resp| check_for_error(resp) }
        puts response.body["logs"].collect{ |log| log["message"]}
        separate
        self
      end

      def publish_pact(consumer: last_consumer_name, consumer_version:, provider: last_provider_name, content_id:, tag: nil, branch: nil)
        @last_consumer_name = consumer
        @last_provider_name = provider
        @last_consumer_version_number = consumer_version

        create_version(pacticipant: consumer, version: consumer_version, branch: branch) if branch

        [*tag].each do | t |
          create_tag(pacticipant: consumer, version: consumer_version, tag: t)
        end
        puts "" if [*tag].any?

        content = generate_content(consumer, provider, content_id)
        puts "Publishing pact for consumer #{consumer} version #{consumer_version} and provider #{provider}"
        pact_path = "pacts/provider/#{encode(provider)}/consumer/#{encode(consumer)}/version/#{encode(consumer_version)}"
        @publish_pact_response = client.put(pact_path, content).tap { |response| check_for_error(response) }
        separate
        self
      end

      def get_pacts_for_verification(provider: last_provider_name, provider_version_tag: nil, provider_version_branch: nil, consumer_version_selectors: nil, enable_pending: nil, include_wip_pacts_since: nil)
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
        if pacts
          puts "Pacts for verification (#{pacts.count}):"
          pacts.each do | pact |
            puts({
              "url" => pact["_links"]["self"]["href"],
              "wip" => pact["verificationProperties"]["wip"],
              "pending" => pact["verificationProperties"]["pending"],
              "why" => pact["verificationProperties"]["notices"].select { | n | n["when"] == "before_verification" }.collect{ | n | n["text"] }
            }.to_yaml)
          end
        end
        self
      end

      def verify_latest_pact_for_tag(success: true, provider: last_provider_name, consumer: last_consumer_name, consumer_version_tag: , provider_version:, provider_version_tag: nil, provider_version_branch: nil)
        @last_provider_name = provider
        @last_consumer_name = consumer

        url_of_pact_to_verify = "pacts/provider/#{encode(provider)}/consumer/#{encode(consumer)}/latest/#{encode(consumer_version_tag)}"
        publish_verification_results(url_of_pact_to_verify, provider, provider_version, provider_version_tag, provider_version_branch, success)
        separate
        self
      end

      def verify_pact(index: 0, success: true, provider: last_provider_name, provider_version_tag: last_provider_version_tag, provider_version_branch: last_provider_version_branch, provider_version: )
        @last_provider_name = provider
        @last_provider_version_tag = provider_version_tag
        @last_provider_version_branch = provider_version_branch

        pact_to_verify = @pacts_for_verification_response.body["_embedded"]["pacts"][index]
        raise "No pact found to verify at index #{index}" unless pact_to_verify
        url_of_pact_to_verify = pact_to_verify["_links"]["self"]["href"]

        publish_verification_results(url_of_pact_to_verify, provider, provider_version, provider_version_tag, provider_version_branch, success)
        separate
        self
      end

      def create_global_webhook_for_event(**kwargs)
        create_webhook_for_event(**kwargs)
      end

      def create_webhook_for_event(uuid: nil, url: "https://postman-echo.com/post", body: nil, provider: nil, consumer: nil, event_name:)
        require "securerandom"
        webhook_prefix = "global " if provider.nil? && consumer.nil?
        puts "Creating #{webhook_prefix}webhook for contract changed event with uuid #{uuid}"
        uuid ||= SecureRandom.uuid
        default_body = {
          "pactUrl" => "${pactbroker.pactUrl}",
          "eventName" => "${pactbroker.eventName}",
          "consumerName" => "${pactbroker.consumerName}",
          "consumerVersionNumber" => "${pactbroker.consumerVersionNumber}",
          "providerVersionBranch" => "${pactbroker.providerVersionBranch}",
          "providerName" => "${pactbroker.providerName}",
          "providerVersionNumber" => "${pactbroker.providerVersionNumber}",
          "providerVersionDescriptions" => "${pactbroker.providerVersionDescriptions}",
          "consumerVersionBranch" => "${pactbroker.consumerVersionBranch}",
        }
        request_body = {
          "consumer" => consumer,
          "provider" => provider,
          "description" => webhook_description(consumer, provider),
          "events" => Array(event_name).map { |name| {"name" => name} },
          "request" => {
            "method" => "POST",
            "url" => url,
            "body" => body || default_body
          }
        }.compact
        path = "webhooks/#{uuid}"
        client.put(path, request_body.to_json).tap { |response| check_for_error(response) }
        separate
        self
      end

      def create_global_webhook_for_contract_changed(uuid: nil, url: "https://postman-echo.com/post", body: nil)
        create_global_webhook_for_event(uuid: uuid, url: url, body: body, event_name: "contract_content_changed")
      end

      def create_global_webhook_for_anything_published(uuid: nil, url: "https://postman-echo.com/post")
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
              "consumerVersionBranch" => "${pactbroker.consumerVersionBranch}",
              "githubVerificationStatus" => "${pactbroker.githubVerificationStatus}",
              "providerVersionNumber" => "${pactbroker.providerVersionNumber}",
              "providerVersionTags" => "${pactbroker.providerVersionTags}",
              "providerVersionBranch" => "${pactbroker.providerVersionBranch}",
              "canIMerge" => "${pactbroker.providerMainBranchGithubVerificationStatus}"
            }
          }
        }
        path = "webhooks/#{uuid}"
        client.put(path, request_body.to_json).tap { |response| check_for_error(response) }
        separate
        self
      end

      def delete_webhook(uuid:)
        puts "Deleting webhook with uuid #{uuid}"
        path = "webhooks/#{uuid}"
        client.delete(path).tap { |response| check_for_error(response) }
        separate
        self
      end

      def print_pacts_for_verification_response
        puts @pacts_for_verification_response.body
        self
      end

      def can_i_deploy(pacticipant:, version:, to: nil, to_environment: nil)
        can_i_deploy_response = client.get("can-i-deploy", { pacticipant: pacticipant, version: version, to: to, environment: to_environment}.compact ).tap { |response| check_for_error(response) }
        can = !!(can_i_deploy_response.body["summary"] || {})["deployable"]
        puts "can-i-deploy #{pacticipant} version #{version} to #{to || to_environment}: #{can ? 'yes' : 'no'}"
        summary = can_i_deploy_response.body["summary"]
        verification_result_urls = (can_i_deploy_response.body["matrix"] || []).collect do | row |
          row.dig("verificationResult", "_links", "self", "href")
        end.compact
        summary.merge!("verification_result_urls" => verification_result_urls)
        puts summary.to_yaml
        separate
        self
      end

      def can_i_merge(pacticipant:, version:)
        can_i_merge_response = client.get("matrix", { q: [pacticipant: pacticipant, version: version], latestby: "cvp", mainBranch: true, latest: true }.compact ).tap { |response| check_for_error(response) }
        can = !!(can_i_merge_response.body["summary"] || {})["deployable"]
        puts "can-i-merge #{pacticipant} version #{version}: #{can ? 'yes' : 'no'}"
        summary = can_i_merge_response.body["summary"]
        verification_result_urls = (can_i_merge_response.body["matrix"] || []).collect do | row |
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

      def webhook_description(consumer, provider)
        return "A webhook for all consumers and providers" if consumer.nil? && provider.nil?

        suffix = {consumer: consumer, provider: provider}.compact.map do |name, pacticipant|
          desc = pacticipant.compact.map { |k, v| "#{k}: '#{v}'"}.first
          "#{name}s by #{desc}"
        end

        "A webhook for #{suffix.join(' and ')}"
      end

      def publish_verification_results(url_of_pact_to_verify, provider, provider_version, provider_version_tag, provider_version_branch, success)
        [*provider_version_tag].each do | tag |
          create_tag(pacticipant: provider, version: provider_version, tag: tag)
        end
        puts "" if [*provider_version_tag].any?

        create_version(pacticipant: provider, version: provider_version, branch: provider_version_branch) if provider_version_branch

        pact_response = client.get(url_of_pact_to_verify).tap { |response| check_for_error(response) }
        verification_results_url = pact_response.body["_links"]["pb:publish-verification-results"]["href"]

        results = {
          success: success,
          testResults: [],
          providerApplicationVersion: provider_version
        }
        puts "Publishing verification"
        puts results.to_yaml
        client.post(verification_results_url, results.to_json).tap { |response| check_for_error(response) }
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
