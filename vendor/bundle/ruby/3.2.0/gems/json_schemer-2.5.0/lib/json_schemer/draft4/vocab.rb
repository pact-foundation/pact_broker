# frozen_string_literal: true
module JSONSchemer
  module Draft4
    module Vocab
      ALL = Draft6::Vocab::ALL.dup
      ALL.transform_keys! { |key| key == '$id' ? 'id' : key }
      ALL.delete('contains')
      ALL.delete('propertyNames')
      ALL.delete('const')
      ALL.delete('examples')
      ALL.merge!(
        'type' => Validation::Type,
        'exclusiveMaximum' => Validation::ExclusiveMaximum,
        'exclusiveMinimum' => Validation::ExclusiveMinimum
      )
    end
  end
end
