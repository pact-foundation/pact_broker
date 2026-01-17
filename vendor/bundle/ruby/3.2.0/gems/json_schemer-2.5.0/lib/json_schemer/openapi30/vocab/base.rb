# frozen_string_literal: true
module JSONSchemer
  module OpenAPI30
    module Vocab
      module Base
        class Type < Draft4::Vocab::Validation::Type
          def parse
            if schema.value['nullable'] == true
              (Array(value) + ['null']).uniq
            else
              super
            end
          end
        end
      end
    end
  end
end
