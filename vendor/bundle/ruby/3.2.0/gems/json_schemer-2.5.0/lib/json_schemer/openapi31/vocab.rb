# frozen_string_literal: true
module JSONSchemer
  module OpenAPI31
    module Vocab
      # https://spec.openapis.org/oas/latest.html#schema-object
      BASE = {
        # https://spec.openapis.org/oas/latest.html#discriminator-object
        'discriminator' => Base::Discriminator,
        'allOf' => Base::AllOf,
        'anyOf' => Base::AnyOf,
        'oneOf' => Base::OneOf
        # 'xml' => Base::Xml,
        # 'externalDocs' => Base::ExternalDocs,
        # 'example' => Base::Example
      }
    end
  end
end
