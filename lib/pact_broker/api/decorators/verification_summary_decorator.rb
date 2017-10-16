require_relative 'base_decorator'
require_relative 'version_decorator'
require_relative 'verification_decorator'
require 'ostruct'

module PactBroker
  module Api
    module Decorators

      class VerificationSummaryDecorator < BaseDecorator

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

        def provider_summary
          OpenStruct.new(
            successful: represented.select(&:success).collect(&:provider_name),
            failed: represented.select{|verification| !verification.success }.collect(&:provider_name))
        end

      end
    end
  end
end
