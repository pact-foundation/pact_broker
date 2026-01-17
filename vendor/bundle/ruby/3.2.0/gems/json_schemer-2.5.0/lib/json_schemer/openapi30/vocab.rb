# frozen_string_literal: true
module JSONSchemer
  module OpenAPI30
    module Vocab
      # https://spec.openapis.org/oas/v3.0.3#schema-object
      BASE = OpenAPI31::Vocab::BASE.merge(
        # https://spec.openapis.org/oas/v3.0.3#fixed-fields-19
        'type' => Base::Type
      )
    end
  end
end
