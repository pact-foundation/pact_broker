module PactBroker
  module Versions
    class AbbreviateNumber

      def self.call version_number
        return version_number unless version_number

        # hard limit of max 50 characters
        version_length = version_number.length
        return version_number[0...39] + "…" + version_number[version_length - 10...version_length] if version_length > 50

        version_number.gsub(/[A-Za-z0-9]{40}/) do | val |
          val[0..6]
        end
      end
    end
  end
end
