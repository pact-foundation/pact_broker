# frozen_string_literal: true
module JSONSchemer
  module Draft7
    module Vocab
      ALL = Draft201909::Vocab::CORE.dup
      ALL.delete('$recursiveAnchor')
      ALL.delete('$recursiveRef')
      ALL.delete('$vocabulary')
      ALL.delete('$anchor')
      ALL.delete('$defs')
      ALL.merge!(Draft201909::Vocab::APPLICATOR)
      ALL.delete('dependentSchemas')
      ALL.delete('unevaluatedItems')
      ALL.delete('unevaluatedProperties')
      ALL.merge!(Draft201909::Vocab::VALIDATION)
      ALL.delete('dependentRequired')
      ALL.delete('maxContains')
      ALL.delete('minContains')
      ALL.merge!(Draft202012::Vocab::FORMAT_ANNOTATION)
      ALL.merge!(Draft201909::Vocab::META_DATA)
      ALL.delete('deprecated')
      ALL.merge!(
        '$ref' => Validation::Ref,
        'additionalItems' => Validation::AdditionalItems,
        'contentEncoding' => Validation::ContentEncoding,
        'contentMediaType' => Validation::ContentMediaType
      )
    end
  end
end
