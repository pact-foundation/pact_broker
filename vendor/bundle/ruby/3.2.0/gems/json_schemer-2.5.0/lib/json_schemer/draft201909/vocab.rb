# frozen_string_literal: true
module JSONSchemer
  module Draft201909
    module Vocab
      CORE = Draft202012::Vocab::CORE.dup
      CORE.delete('$dynamicAnchor')
      CORE.delete('$dynamicRef')
      CORE.merge!(
        # https://datatracker.ietf.org/doc/html/draft-handrews-json-schema-02#section-8.2.4.2
        '$recursiveAnchor' => Core::RecursiveAnchor,
        '$recursiveRef' => Core::RecursiveRef
      )

      APPLICATOR = Draft202012::Vocab::APPLICATOR.dup
      APPLICATOR.delete('prefixItems')
      APPLICATOR.merge!(
        # https://datatracker.ietf.org/doc/html/draft-handrews-json-schema-02#section-9.3.1
        'items' => Applicator::Items,
        'additionalItems' => Applicator::AdditionalItems,
        'unevaluatedItems' => Applicator::UnevaluatedItems,
        # https://datatracker.ietf.org/doc/html/draft-handrews-json-schema-02#section-9.3.2.4
        'unevaluatedProperties' => Draft202012::Vocab::Unevaluated::UnevaluatedProperties
      )

      VALIDATION = Draft202012::Vocab::VALIDATION
      FORMAT = Draft202012::Vocab::FORMAT_ANNOTATION
      CONTENT = Draft202012::Vocab::CONTENT
      META_DATA = Draft202012::Vocab::META_DATA
    end
  end
end
