# frozen_string_literal: true
module JSONSchemer
  Configuration = Struct.new(
    :base_uri, :meta_schema, :vocabulary, :format, :formats, :content_encodings, :content_media_types, :keywords,
    :before_property_validation, :after_property_validation, :insert_property_defaults, :property_default_resolver,
    :ref_resolver, :regexp_resolver, :output_format, :resolve_enumerators, :access_mode,
    keyword_init: true
  ) do
    def initialize(
      base_uri: URI('json-schemer://schema'),
      meta_schema: Draft202012::BASE_URI.to_s,
      vocabulary: nil,
      format: true,
      formats: {},
      content_encodings: {},
      content_media_types: {},
      keywords: {},
      before_property_validation: [],
      after_property_validation: [],
      insert_property_defaults: false,
      property_default_resolver: nil,
      ref_resolver: proc { |uri| raise UnknownRef, uri.to_s },
      regexp_resolver: 'ruby',
      output_format: 'classic',
      resolve_enumerators: false,
      access_mode: nil
    )
      super
    end
  end
end
