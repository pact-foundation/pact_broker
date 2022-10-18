require "json"
require "pact_broker/string_refinements"
require "pact_broker/repositories"
require "pact_broker/services"
require "pact_broker/webhooks/repository"
require "pact_broker/webhooks/service"
require "pact_broker/webhooks/trigger_service"
require "pact_broker/webhooks/webhook_execution_result"
require "pact_broker/pacts/repository"
require "pact_broker/pacts/service"
require "pact_broker/pacts/content"
require "pact_broker/pacticipants/repository"
require "pact_broker/pacticipants/service"
require "pact_broker/versions/repository"
require "pact_broker/versions/service"
require "pact_broker/tags/repository"
require "pact_broker/labels/repository"
require "pact_broker/tags/service"
require "pact_broker/domain"
require "pact_broker/versions/repository"
require "pact_broker/pacts/repository"
require "pact_broker/pacticipants/repository"
require "pact_broker/verifications/repository"
require "pact_broker/verifications/service"
require "pact_broker/tags/repository"
require "pact_broker/webhooks/repository"
require "pact_broker/certificates/certificate"
require "pact_broker/deployments/environment_service"
require "pact_broker/deployments/deployed_version_service"
require "pact_broker/deployments/released_version_service"
require "pact_broker/versions/branch_version_repository"
require "pact_broker/integrations/repository"
require "pact_broker/contracts/service"

require "ostruct"

module PactBroker
  module Test
    class TestDataBuilder
      include PactBroker::Repositories
      include PactBroker::Services
      using PactBroker::StringRefinements


      attr_reader :pacticipant
      attr_reader :consumer
      attr_reader :provider
      attr_reader :consumer_version
      attr_reader :provider_version
      attr_reader :version
      attr_reader :pact
      attr_reader :pact_version
      attr_reader :verification
      attr_reader :webhook
      attr_reader :webhook_execution
      attr_reader :triggered_webhook
      attr_reader :environment
      attr_reader :deployed_version
      attr_reader :released_version

      def initialize(_params = {})
        @now = DateTime.now
      end

      def comment *_args
        self
      end

      def create_pricing_service
        create_provider("Pricing Service", :repository_url => "git@git.realestate.com.au:business-systems/pricing-service")
        self
      end

      def create_contract_proposal_service
        create_provider("Contract Proposal Service", :repository_url => "git@git.realestate.com.au:business-systems/contract-proposal-service")
        self
      end

      def create_contract_email_service
        create_consumer("Contract Email Service", :repository_url => "git@git.realestate.com.au:business-systems/contract-email-service")
        self
      end

      def create_condor
        create_consumer("Condor")
        self
      end

      def create_pact_with_hierarchy consumer_name = "Consumer", consumer_version_number = "1.2.3", provider_name = "Provider", json_content = nil
        use_consumer(consumer_name)
        create_consumer(consumer_name) if !consumer
        use_provider(provider_name)
        create_provider provider_name if !provider
        use_consumer_version(consumer_version_number)
        create_consumer_version(consumer_version_number) if !consumer_version
        create_pact json_content: json_content || default_json_content
        self
      end

      def create_pact_with_consumer_version_tag consumer_name, consumer_version_number, consumer_version_tag_name, provider_name
        create_pact_with_hierarchy(consumer_name, consumer_version_number, provider_name)
        create_consumer_version_tag(consumer_version_tag_name)
        self
      end

      def create_pact_with_verification consumer_name = "Consumer", consumer_version = "1.0.#{model_counter}", provider_name = "Provider", provider_version = "1.0.#{model_counter}", success = true
        create_pact_with_hierarchy(consumer_name, consumer_version, provider_name)
        create_verification(number: model_counter, provider_version: provider_version, success: success)
        self
      end

      def create_pact_with_verification_and_tags consumer_name = "Consumer", consumer_version = "1.0.#{model_counter}", consumer_version_tags = [], provider_name = "Provider", provider_version = "1.0.#{model_counter}", provider_version_tags = []
        create_pact_with_hierarchy(consumer_name, consumer_version, provider_name)
        consumer_version_tags.each do | tag |
          create_consumer_version_tag(tag)
        end
        create_verification(number: model_counter, provider_version: provider_version, tag_names: provider_version_tags)
        self
      end

      def create_version_with_hierarchy pacticipant_name, pacticipant_version
        pacticipant = pacticipant_service.create(:name => pacticipant_name)
        version = PactBroker::Domain::Version.create(:number => pacticipant_version, :pacticipant => pacticipant)
        @version = PactBroker::Domain::Version.find(id: version.id) # Get version with populated order
        self
      end

      def create_tag_with_hierarchy pacticipant_name, pacticipant_version, tag_name
        create_version_with_hierarchy pacticipant_name, pacticipant_version
        PactBroker::Domain::Tag.create(name: tag_name, version: @version)
        self
      end

      def create_pacticipant pacticipant_name, params = {}
        params.delete(:comment)
        repository_url = "https://github.com/#{params[:repository_namespace] || "example-organization"}/#{params[:repository_name] || pacticipant_name}"
        merged_params = { name: pacticipant_name, repository_url: repository_url }.merge(params)
        @pacticipant = PactBroker::Domain::Pacticipant.create(merged_params)
        self
      end

      def create_consumer consumer_name = "Consumer #{model_counter}", params = {}
        params.delete(:comment)
        create_pacticipant consumer_name, params
        @consumer = @pacticipant
        self
      end

      def use_consumer consumer_name, params = {}
        params.delete(:comment)
        @consumer = PactBroker::Domain::Pacticipant.find(:name => consumer_name)
        self
      end

      def create_provider provider_name = "Provider #{model_counter}", params = {}
        params.delete(:comment)
        create_pacticipant provider_name, params
        @provider = @pacticipant
        self
      end

      def create_integration
        PactBroker::Integrations::Repository.new.create_for_pact(consumer.id, provider.id)
        self
      end

      def use_provider provider_name
        @provider = PactBroker::Domain::Pacticipant.find(:name => provider_name)
        self
      end

      def create_version version_number = "1.0.#{model_counter}", params = {}
        @version = create_pacticipant_version(version_number, pacticipant, params)
        self
      end

      def create_consumer_version version_number = "1.0.#{model_counter}", params = {}
        @consumer_version = create_pacticipant_version(version_number, consumer, params)
        self
      end

      def create_provider_version version_number = "1.0.#{model_counter}", params = {}
        @provider_version = create_pacticipant_version(version_number, provider, params)
        self
      end

      def use_consumer_version version_number
        @consumer_version = PactBroker::Domain::Version.where(pacticipant_id: @consumer.id, number: version_number).single_record
        self
      end

      def use_provider_version version_number
        @provider_version = PactBroker::Domain::Version.where(pacticipant_id: @provider.id, number: version_number).single_record
        self
      end

      def create_tag tag_name, params = {}
        params.delete(:comment)
        @tag = PactBroker::Domain::Tag.create(name: tag_name, version: @version, version_order: @version.order, pacticipant_id: @version.pacticipant_id)
        set_created_at_if_set params[:created_at], :tags, { name: @tag.name, version_id: @tag.version_id }
        self
      end

      def create_consumer_version_tag tag_name, params = {}
        params.delete(:comment)
        @tag = PactBroker::Domain::Tag.create(name: tag_name, version: @consumer_version)
        set_created_at_if_set params[:created_at], :tags, { name: @tag.name, version_id: @tag.version_id }
        self
      end

      def create_provider_version_tag tag_name, params = {}
        params.delete(:comment)
        @tag = PactBroker::Domain::Tag.create(name: tag_name, version: @provider_version)
        set_created_at_if_set params[:created_at], :tags, { name: @tag.name, version_id: @tag.version_id }
        self
      end

      def create_label label_name
        @label = PactBroker::Domain::Label.create(name: label_name, pacticipant: @pacticipant)
        self
      end

      def publish_pact(consumer_name:, provider_name:, consumer_version_number: , tags: nil, branch: nil, build_url: nil, json_content: nil)
        json_content = json_content || random_json_content(consumer_name, provider_name)
        contracts = [
          PactBroker::Contracts::ContractToPublish.from_hash(consumer_name: consumer_name, provider_name: provider_name, decoded_content: json_content, content_type: "application/json", specification: "pact")
        ]
        contracts_to_publish = PactBroker::Contracts::ContractsToPublish.from_hash(
          pacticipant_name: consumer_name,
          pacticipant_version_number: consumer_version_number,
          tags: tags,
          branch: branch,
          build_url: build_url,
          contracts: contracts
        )
        PactBroker::Contracts::Service.publish(contracts_to_publish, base_url: "http://example.org")
        @consumer = find_pacticipant(consumer_name)
        @consumer_version = find_version(consumer_name, consumer_version_number)
        @provider = find_pacticipant(provider_name)
        @pact = PactBroker::Pacts::PactPublication.last.to_domain
        self
      end

      def create_pact params = {}
        params.delete(:comment)
        json_content = params[:json_content] || default_json_content
        pact_version_sha = params[:pact_version_sha] || generate_pact_version_sha(json_content)
        pact_versions_count_before = PactBroker::Pacts::PactVersion.count
        @pact = PactBroker::Pacts::Repository.new.create(
          version_id: @consumer_version.id,
          consumer_id: @consumer.id,
          provider_id: @provider.id,
          pact_version_sha: pact_version_sha,
          json_content: prepare_json_content(json_content),
          version: @consumer_version
        )
        pact_versions_count_after = PactBroker::Pacts::PactVersion.count
        set_created_at_if_set(params[:created_at], :pact_publications, id: @pact.id)
        set_created_at_if_set(params[:created_at], :pact_versions, sha: @pact.pact_version_sha) if pact_versions_count_after > pact_versions_count_before
        set_created_at_if_set(params[:created_at], :latest_pact_publication_ids_for_consumer_versions, consumer_version_id: @consumer_version.id)
        @pact = PactBroker::Pacts::PactPublication.find(id: @pact.id).to_domain
        consumer_version.reload
        consumer_version.pact_publications.each{ | pp | pp.allow_lazy_load if pp.respond_to?(:allow_lazy_load) }
        self
      end

      def create_pact_with_different_content params = {}
        create_pact(params.merge(json_content: random_json_content(consumer.name, provider.name)))
      end

      def republish_same_pact params = {}
        params.delete(:comment)
        last_pact_version = PactBroker::Pacts::PactVersion.order(:id).last
        create_pact pact_version_sha: last_pact_version.sha, json_content: last_pact_version.content, created_at: params[:created_at]
        self
      end

      def revise_pact json_content = nil
        json_content = json_content ? json_content : {random: rand}.to_json
        pact_version_sha = generate_pact_version_sha(json_content)
        @pact = PactBroker::Pacts::Repository.new.update(@pact.id,
          json_content: prepare_json_content(json_content),
          pact_version_sha: pact_version_sha
        )
        self
      end

      def create_pact_version_without_publication(json_content = nil )
        json_content = json_content ? json_content : {random: rand}.to_json
        pact_version_sha = generate_pact_version_sha(json_content)

        @pact_version = PactBroker::Pacts::PactVersion.new(
          consumer_id: consumer.id,
          provider_id: provider.id,
          sha: pact_version_sha,
          content: json_content,
          created_at: Sequel.datetime_class.now
        ).save
        self
      end

      def create_webhook parameters = {}
        params = parameters.dup
        consumer, webhook_consumer = webhook_pacticipant(:consumer, params)
        provider, webhook_provider = webhook_pacticipant(:provider, params)
        uuid = params[:uuid] || PactBroker::Webhooks::Service.next_uuid
        enabled = params.key?(:enabled) ? params.delete(:enabled) : true
        event_params = if params[:event_names]
                         params[:event_names].collect{ |event_name| {name: event_name} }
                       else
                         params[:events] || [{ name: PactBroker::Webhooks::WebhookEvent::DEFAULT_EVENT_NAME }]
                       end
        events = event_params.collect{ |e| PactBroker::Webhooks::WebhookEvent.new(e) }
        template_params = { method: "POST", url: "http://example.org", headers: {"Content-Type" => "application/json"}, username: params[:username], password: params[:password] }
        request = PactBroker::Webhooks::WebhookRequestTemplate.new(template_params.merge(params))
        new_webhook = PactBroker::Domain::Webhook.new(
          request: request,
          events: events,
          description: params[:description],
          enabled: enabled,
          consumer: webhook_consumer,
          provider: webhook_provider
        )
        @webhook = PactBroker::Webhooks::Repository.new.create uuid, new_webhook, consumer, provider
        set_created_at_if_set(params[:created_at], :webhooks, uuid: @webhook.uuid)
        self
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def create_verification_webhook parameters = {}
        create_webhook(parameters.merge(event_names: [PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED]))
      end

      def create_global_webhook parameters = {}
        create_webhook(parameters.merge(consumer: nil, provider: nil))
      end

      def create_global_contract_published_webhook parameters = {}
        create_webhook(parameters.merge(consumer: nil, provider: nil, event_names: [PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED]))
      end

      def create_global_contract_content_changed_webhook parameters = {}
        create_webhook(parameters.merge(consumer: nil, provider: nil, event_names: [PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED]))
      end

      def create_global_verification_webhook parameters = {}
        create_webhook(parameters.merge(consumer: nil, provider: nil, event_names: [PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED]))
      end

      def create_global_verification_succeeded_webhook parameters = {}
        create_webhook(parameters.merge(consumer: nil, provider: nil, event_names: [PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED]))
      end

      def create_global_verification_failed_webhook parameters = {}
        create_webhook(parameters.merge(consumer: nil, provider: nil, event_names: [PactBroker::Webhooks::WebhookEvent::VERIFICATION_FAILED]))
      end

      def create_provider_webhook parameters = {}
        create_webhook(parameters.merge(consumer: nil))
      end

      def create_consumer_webhook parameters = {}
        create_webhook(parameters.merge(provider: nil))
      end

      def create_triggered_webhook params = {}
        params.delete(:comment)
        uuid = params[:uuid] || webhook_service.next_uuid
        event_name = params.key?(:event_name) ? params[:event_name] : @webhook.events.first.name # could be nil, for backwards compatibility
        verification = @webhook.trigger_on_provider_verification_published? ? @verification : nil
        event_context = params[:event_context]
        @triggered_webhook = webhook_repository.create_triggered_webhook(uuid, @webhook, @pact, verification, PactBroker::Webhooks::TriggerService::RESOURCE_CREATION, event_name, event_context)
        @triggered_webhook.update(status: params[:status]) if params[:status]
        set_created_at_if_set params[:created_at], :triggered_webhooks, { id: @triggered_webhook.id }
        self
      end

      def create_webhook_execution params = {}
        params.delete(:comment)
        logs = params[:logs] || "logs"
        webhook_execution_result = PactBroker::Webhooks::WebhookExecutionResult.new(nil, OpenStruct.new(code: "200"), true, logs, nil)
        @webhook_execution = PactBroker::Webhooks::Repository.new.create_execution @triggered_webhook, webhook_execution_result
        created_at = params[:created_at] || @pact.created_at + Rational(1, 86400)
        set_created_at_if_set created_at, :webhook_executions, {id: @webhook_execution.id}
        @webhook_execution = PactBroker::Webhooks::Execution.find(id: @webhook_execution.id)
        self
      end

      def create_verification parameters = {}
        # This should use the verification service. what a mess
        parameters.delete(:comment)
        branch = parameters.delete(:branch)
        tag_names = [parameters.delete(:tag_names), parameters.delete(:tag_name)].flatten.compact
        provider_version_number = parameters[:provider_version] || "4.5.6"
        default_parameters = { success: true, number: 1, test_results: { some: "results" }, wip: false }
        default_parameters[:execution_date] = @now if @now
        parameters = default_parameters.merge(parameters)
        parameters.delete(:provider_version)
        verification = PactBroker::Domain::Verification.new(parameters)
        pact_version = PactBroker::Pacts::Repository.new.find_pact_version(@consumer, @provider, pact.pact_version_sha)
        @provider_version = version_repository.find_by_pacticipant_id_and_number_or_create(provider.id, provider_version_number)
        branch_version = PactBroker::Versions::BranchVersionRepository.new.add_branch(@provider_version, branch) if branch

        if tag_names.any?
          tag_names.each do | tag_name |
            PactBroker::Domain::Tag.new(name: tag_name, version: @provider_version, version_order: @provider_version.order).insert_ignore
            set_created_at_if_set(parameters[:created_at], :tags, version_id: @provider_version.id, name: tag_name)
          end
        end

        @verification = PactBroker::Verifications::Repository.new.create(verification, provider_version_number, pact_version)


        if branch
          set_created_at_if_set(parameters[:created_at], :branch_versions, id: branch_version.id)

          # if the branch has just been created...
          if branch_version.branch.branch_versions.size == 1
            set_created_at_if_set(parameters[:created_at], :branches, id: branch_version.branch.id)
          end
        end

        set_created_at_if_set(parameters[:created_at], :verifications, id: @verification.id)
        set_created_at_if_set(parameters[:created_at], :versions, id: @provider_version.id)
        set_created_at_if_set(parameters[:created_at], :latest_verification_id_for_pact_version_and_provider_version, pact_version_id: pact_version_id, provider_version_id: @provider_version.id)
        set_created_at_if_set(parameters[:created_at], :pact_version_provider_tag_successful_verifications, { verification_id: @verification.id }, :execution_date)

        self
      end

      def create_certificate options = {path: "spec/fixtures/single-certificate.pem"}
        options.delete(:comment)
        PactBroker::Certificates::Certificate.create(uuid: SecureRandom.urlsafe_base64, content: File.read(options[:path]))
        self
      end

      def create_environment(name, params = {})
        uuid = params[:uuid] || PactBroker::Deployments::EnvironmentService.next_uuid
        production = params[:production] || false
        display_name = params[:display_name] || name.camelcase(true)
        the_params = params.merge(name: name, production: production, display_name: display_name)
        @environment = PactBroker::Deployments::EnvironmentService.create(uuid, PactBroker::Deployments::Environment.new(the_params))
        set_created_at_if_set(params[:created_at], :environments, id: environment.id)
        self
      end

      def create_deployed_version_for_consumer_version(uuid: SecureRandom.uuid, currently_deployed: true, environment_name: environment&.name, target: nil, created_at: nil)
        create_deployed_version(uuid: uuid, currently_deployed: currently_deployed, version: consumer_version, environment_name: environment_name, target: target, created_at: created_at)
        self
      end

      def create_deployed_version_for_provider_version(uuid: SecureRandom.uuid, currently_deployed: true, environment_name: environment&.name, target: nil, created_at: nil)
        create_deployed_version(uuid: uuid, currently_deployed: currently_deployed, version: provider_version, environment_name: environment_name, target: target, created_at: created_at)
        self
      end

      def create_released_version_for_consumer_version(uuid: SecureRandom.uuid, currently_supported: true, environment_name: environment&.name, created_at: nil)
        create_released_version(uuid: uuid, currently_supported: currently_supported, version: consumer_version, environment_name: environment_name, created_at: created_at)
        self
      end

      def create_released_version_for_provider_version(uuid: SecureRandom.uuid, currently_supported: true, environment_name: environment&.name, created_at: nil)
        create_released_version(uuid: uuid, currently_supported: currently_supported, version: provider_version, environment_name: environment_name, created_at: created_at)
        self
      end


      def create_everything_for_an_integration
        create_pact_with_verification("Foo", "1", "Bar", "2")
          .create_label("label")
          .create_consumer_version_tag("master")
          .create_provider_version_tag("master")
          .create_webhook
          .create_triggered_webhook
          .create_webhook_execution
          .create_environment("test")
          .create_deployed_version_for_consumer_version
          .create_released_version_for_consumer_version
      end

      def find_pacticipant(name)
        PactBroker::Domain::Pacticipant.where(name: name).single_record
      end

      def find_version(pacticipant_name, version_number)
        PactBroker::Domain::Version.for(pacticipant_name, version_number)
      end

      def find_pact(consumer_name, consumer_version_number, provider_name)
        pact_repository.find_pact(consumer_name, consumer_version_number, provider_name)
      end

      def find_pact_publication(consumer_name, consumer_version_number, provider_name)
        PactBroker::Pacts::PactPublication
          .remove_overridden_revisions
          .where(provider: find_pacticipant(provider_name))
          .where(consumer_version: find_version(consumer_name, consumer_version_number))
          .single_record
      end

      def find_environment(environment_name)
        PactBroker::Deployments::EnvironmentService.find_by_name(environment_name)
      end

      def model_counter
        @@model_counter ||= 0
        @@model_counter += 1
        @@model_counter
      end

      def and_return instance_variable_name
        instance_variable_get("@#{instance_variable_name}")
      end

      def set_now date
        @now = date.to_date
        self
      end

      def set_now_date_time date_time
        @now = date_time
        self
      end

      def add_day
        @now = @now + 1
        self
      end

      def add_days(days = 1)
        @now = @now + days
        self
      end

      def subtract_day
        @now = @now - 1
        self
      end

      def subtract_days(days = 1)
        @now = @now - days
        self
      end

      def add_minute
        @now = @now + (1.0/(24*60))
        self
      end

      def add_five_minutes
        @now = @now + (1.0/(24*60)*5)
        self
      end

      def in_utc
        original_tz = ENV["TZ"]
        begin
          ENV["TZ"] = "UTC"
          yield
        ensure
          ENV["TZ"] = original_tz
        end
      end

      def random_json_content(consumer_name, provider_name)
        {
          "consumer" => {
             "name" => consumer_name
           },
           "provider" => {
             "name" => provider_name
           },
           "interactions" => [{
              "request" => {
                "method" => "GET",
                "path" => "/things/#{rand}"
              },
              "response" => {
                "status" => 200
              }
           }],
         }.to_json
      end

      def fixed_json_content(consumer_name, provider_name, differentiator)
        {
          "consumer" => {
             "name" => consumer_name
           },
           "provider" => {
             "name" => provider_name
           },
           "interactions" => [{
              "request" => {
                "method" => "GET",
                "path" => "/things/#{differentiator}"
              },
              "response" => {
                "status" => 200
              }
           }],
         }.to_json
      end

      private

      def create_pacticipant_version(version_number, pacticipant, params = {})
        params.delete(:comment)
        tag_names = [params.delete(:tag_names), params.delete(:tag_name)].flatten.compact
        args = {
          number: version_number,
          pacticipant_id: pacticipant.id,
          branch: params[:branch],
          build_url: params[:build_url]
        }

        version = PactBroker::Versions::Repository.new.create(args)

        set_created_at_if_set params[:created_at], :versions, { id: version.id }
        tag_names.each do | tag_name |
          tag = PactBroker::Domain::Tag.create(name: tag_name, version: version)
          set_created_at_if_set(params[:created_at], :tags, { name: tag.name, version_id: version.id })
        end
        version
      end

      def create_deployed_version(uuid: , currently_deployed: , version:, environment_name: , target: nil, created_at: nil)
        env = find_environment(environment_name)
        @deployed_version = PactBroker::Deployments::DeployedVersionService.find_or_create(uuid, version, env, target)
        PactBroker::Deployments::DeployedVersionService.record_version_undeployed(deployed_version) unless currently_deployed
        set_created_at_if_set(created_at, :deployed_versions, id: deployed_version.id)
      end

      def create_released_version(uuid: , currently_supported: true, version:, environment_name: , created_at: nil)
        env = find_environment(environment_name)
        @released_version = PactBroker::Deployments::ReleasedVersionService.create_or_update(uuid, version, env)
        PactBroker::Deployments::ReleasedVersionService.record_version_support_ended(released_version) unless currently_supported
        released_version.refresh
        set_created_at_if_set(created_at, :released_versions, id: released_version.id)
      end

      def pact_version_id
        PactBroker::Pacts::PactPublication.find(id: @pact.id).pact_version_id
      end

      # Remember! This must be called before adding the IDs
      def generate_pact_version_sha json_content
        PactBroker.configuration.sha_generator.call(json_content)
      end

      def prepare_json_content(json_content)
        PactBroker::Pacts::Content.from_json(json_content).with_ids(false).to_json
      end

      def set_created_at_if_set created_at, table_name, selector, date_column_name = :created_at
        date_to_set = created_at || @now
        if date_to_set
          Sequel::Model.db[table_name].where(selector).update(date_column_name => date_to_set)
          if Sequel::Model.db.schema(table_name).any?{ |col| col.first == :updated_at }
            Sequel::Model.db[table_name].where(selector.keys.first => selector.values.first).update(updated_at: date_to_set)
          end
        end
      end

      def default_json_content
        {
          "consumer" => {
             "name" => consumer.name
           },
           "provider" => {
             "name" => provider.name
           },
           "interactions" => [],
           "random" => rand
         }.to_json
      end

      def webhook_pacticipant(name, params)
        pacticipant = params.key?(name) ? params.delete(name) : instance_variable_get(:"@#{name}")
        label = params.delete(:"#{name}_label")
        if pacticipant
          [pacticipant, Domain::WebhookPacticipant.new(name: pacticipant.name)]
        elsif label
          [nil, Domain::WebhookPacticipant.new(label: label)]
        end
      end
    end
  end
end
