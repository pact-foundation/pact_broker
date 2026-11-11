require_relative "base_decorator"
require_relative "version_decorator"
require_relative "verification_decorator"
require "ostruct"

module PactBroker
  module Api
    module Decorators
      class VerificationSummaryDecorator < BaseDecorator

        # TODO count pending failures?
        property :success
        property :provider_summary, as: :providerSummary do
          property :successful
          property :failed
          property :unknown
        end

        collection :verifications, as: :verificationResults, embedded: true, :extend => PactBroker::Api::Decorators::VerificationDecorator

        link :self do | context |
          {
            href: context.fetch(:resource_url),
            title: "Latest verification results for consumer #{context.fetch(:consumer_name)} version #{context.fetch(:consumer_version_number)}"
          }
        end

        # representable passes through the kwargs from to_json as normal args
        def to_hash(options)
          user_options = options.fetch(:user_options, {}).merge(pacts_by_pact_version_sha: represented.pacts_by_pact_version_sha)
          super(options.merge(user_options: user_options))
        end

        def provider_summary
          OpenStruct.new(
            successful: represented.select(&:success).collect(&:provider_name),
            failed: represented.select{|verification| !verification.success }.collect(&:provider_name))
        end
      end
    end
  end
end
