# frozen_string_literal: true
module JSONSchemer
  module Draft202012
    module Vocab
      # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-8
      CORE = {
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-8.1
        '$schema' => Core::Schema,
        '$vocabulary' => Core::Vocabulary,
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-8.2
        '$id' => Core::Id,
        '$anchor' => Core::Anchor,
        '$ref' => Core::Ref,
        '$dynamicAnchor' => Core::DynamicAnchor,
        '$dynamicRef' => Core::DynamicRef,
        '$defs' => Core::Defs,
        'definitions' => Core::Defs,
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-8.3
        '$comment' => Core::Comment,
        # https://github.com/orgs/json-schema-org/discussions/329
        'x-error' => Core::XError
      }
      # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-10
      APPLICATOR = {
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-10.2
        'allOf' => Applicator::AllOf,
        'anyOf' => Applicator::AnyOf,
        'oneOf' => Applicator::OneOf,
        'not' => Applicator::Not,
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-10.2.2
        'if' => Applicator::If,
        'then' => Applicator::Then,
        'else' => Applicator::Else,
        'dependentSchemas' => Applicator::DependentSchemas,
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-10.3
        'prefixItems' => Applicator::PrefixItems,
        'items' => Applicator::Items,
        'contains' => Applicator::Contains,
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-10.3.2
        'properties' => Applicator::Properties,
        'patternProperties' => Applicator::PatternProperties,
        'additionalProperties' => Applicator::AdditionalProperties,
        'propertyNames' => Applicator::PropertyNames,
        'dependencies' => Applicator::Dependencies
      }
      # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-01#section-11
      UNEVALUATED = {
        'unevaluatedItems' => Unevaluated::UnevaluatedItems,
        'unevaluatedProperties' => Unevaluated::UnevaluatedProperties
      }
      # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-6
      VALIDATION = {
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-6.1
        'type' => Validation::Type,
        'enum' => Validation::Enum,
        'const' => Validation::Const,
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-6.2
        'multipleOf' => Validation::MultipleOf,
        'maximum' => Validation::Maximum,
        'exclusiveMaximum' => Validation::ExclusiveMaximum,
        'minimum' => Validation::Minimum,
        'exclusiveMinimum' => Validation::ExclusiveMinimum,
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-6.3
        'maxLength' => Validation::MaxLength,
        'minLength' => Validation::MinLength,
        'pattern' => Validation::Pattern,
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-6.4
        'maxItems' => Validation::MaxItems,
        'minItems' => Validation::MinItems,
        'uniqueItems' => Validation::UniqueItems,
        'maxContains' => Validation::MaxContains,
        'minContains' => Validation::MinContains,
        # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-6.5
        'maxProperties' => Validation::MaxProperties,
        'minProperties' => Validation::MinProperties,
        'required' => Validation::Required,
        'dependentRequired' => Validation::DependentRequired
      }
      # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.2.1
      FORMAT_ANNOTATION = {
        'format' => FormatAnnotation::Format
      }
      # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-7.2.2
      FORMAT_ASSERTION = {
        'format' => FormatAssertion::Format
      }
      # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-8
      CONTENT = {
        'contentEncoding' => Content::ContentEncoding,
        'contentMediaType' => Content::ContentMediaType,
        'contentSchema' => Content::ContentSchema
      }
      # https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-validation-01#section-9
      META_DATA = {
        # 'title' => MetaData::Title,
        # 'description' => MetaData::Description,
        # 'default' => MetaData::Default,
        # 'deprecated' => MetaData::Deprecated,
        'readOnly' => MetaData::ReadOnly,
        'writeOnly' => MetaData::WriteOnly,
        # 'examples' => MetaData::Examples
      }
    end
  end
end
