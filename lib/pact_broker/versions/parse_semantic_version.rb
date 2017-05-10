require 'semver'
require 'pact_broker/configuration'

module PactBroker
  module Versions
    class ParseSemanticVersion


      def self.call string_version
        PactBroker.configuration.semver_formats.each do |semver_format|
          parsed_version = ::SemVer.parse(string_version, semver_format)
          return SemVerWrapper.new(parsed_version, semver_format) unless parsed_version.nil?
        end
        nil
      end

      class SemVerWrapper < SimpleDelegator

        def initialize target, semver_format
          super target
          @semver_format = semver_format
        end

        def to_s
          format(@semver_format)
        end
      end
    end
  end
end
