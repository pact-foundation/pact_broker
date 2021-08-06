module PactBroker
  module Verifications
    class RequiredVerification
      attr_reader :provider_version, :provider_version_descriptions

      def initialize(attributes = {})
        attributes.each do | (name, value) |
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
      end

      def == other
        provider_version == other.provider_version && provider_version_descriptions == other.provider_version_descriptions
      end

      def + other
        if provider_version != other.provider_version
          raise PactBroker::Error.new("Can't + RequiredVerifications with different provider versions (#{provider_version.number}/#{other.provider_version.number})")
        end

        RequiredVerification.new(
          provider_version: provider_version,
          provider_version_descriptions: (provider_version_descriptions + other.provider_version_descriptions).uniq
        )
      end
    end
  end
end
