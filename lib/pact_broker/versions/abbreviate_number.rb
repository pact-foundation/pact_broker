module PactBroker
  module Versions
    class AbbreviateNumber

      def self.call version_number
        if version_number
          version_number.gsub(/[A-Za-z0-9]{40}/) do | val |
            val[0..6]
          end
        end
      end
    end
  end
end
