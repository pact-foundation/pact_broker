require 'semver'

module PactBroker
  module Versions
    class ParseSemanticVersion
      SEMVER_FORMAT = "%M.%m.%p%s%d"

      def self.call string_version
        version = ::SemVer.parse(string_version, SEMVER_FORMAT)
        return SemVerWrapper.new(version) unless version.nil?
      end

      class SemVerWrapper < SimpleDelegator
        def to_s
          format(SEMVER_FORMAT)
        end
      end
    end
  end
end
