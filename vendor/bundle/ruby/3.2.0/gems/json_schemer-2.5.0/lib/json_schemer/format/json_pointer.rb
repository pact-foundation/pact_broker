# frozen_string_literal: true
module JSONSchemer
  module Format
    module JSONPointer
      JSON_POINTER_REGEX_STRING = '(\/([^~\/]|~[01])*)*'
      JSON_POINTER_REGEX = /\A#{JSON_POINTER_REGEX_STRING}\z/.freeze
      RELATIVE_JSON_POINTER_REGEX = /\A(0|[1-9]\d*)(#|#{JSON_POINTER_REGEX_STRING})?\z/.freeze

      def valid_json_pointer?(data)
        JSON_POINTER_REGEX.match?(data)
      end

      def valid_relative_json_pointer?(data)
        RELATIVE_JSON_POINTER_REGEX.match?(data)
      end
    end
  end
end
