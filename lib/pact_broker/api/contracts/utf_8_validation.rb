module PactBroker
  module Api
    module Contracts
      module UTF8Validation
        extend self

        def fragment_before_invalid_utf_8_char(string)
          string.force_encoding("UTF-8").each_char.with_index do | char, index |
            if !char.valid_encoding?
              fragment = index < 100 ? string[0...index] : string[index-100...index]
              return index + 1, fragment
            end
          end
          nil
        end
      end
    end
  end
end
