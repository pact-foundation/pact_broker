# frozen_string_literal: true
module JSONSchemer
  module OpenAPI31
    module Vocab
      module Base
        class AllOf < Draft202012::Vocab::Applicator::AllOf
          attr_accessor :skip_ref_once

          def validate(instance, instance_location, keyword_location, context)
            nested = []
            parsed.each_with_index do |subschema, index|
              if ref_schema = subschema.parsed['$ref']&.ref_schema
                next if skip_ref_once == ref_schema.absolute_keyword_location
                ref_schema.parsed['discriminator']&.skip_ref_once = schema.absolute_keyword_location
              end
              nested << subschema.validate_instance(instance, instance_location, join_location(keyword_location, index.to_s), context)
            end
            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested)
          ensure
            self.skip_ref_once = nil
          end
        end

        class AnyOf < Draft202012::Vocab::Applicator::AnyOf
          def validate(*)
            schema.parsed.key?('discriminator') ? nil : super
          end
        end

        class OneOf < Draft202012::Vocab::Applicator::OneOf
          def validate(*)
            schema.parsed.key?('discriminator') ? nil : super
          end
        end

        class Discriminator < Keyword
          # https://spec.openapis.org/oas/v3.1.0#components-object
          FIXED_FIELD_REGEX = /\A[a-zA-Z0-9\.\-_]+$\z/

          attr_accessor :skip_ref_once

          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} does not match `discriminator` schema"
          end

          def mapping
            @mapping ||= value['mapping'] || {}
          end

          def subschemas_by_property_value
            @subschemas_by_property_value ||= if schema.parsed.key?('anyOf') || schema.parsed.key?('oneOf')
              subschemas = schema.parsed['anyOf']&.parsed || []
              subschemas += schema.parsed['oneOf']&.parsed || []

              subschemas_by_ref = {}
              subschemas_by_schema_name = {}

              subschemas.each do |subschema|
                subschema_ref = subschema.parsed.fetch('$ref').parsed
                subschemas_by_ref[subschema_ref] = subschema

                if subschema_ref.start_with?('#/components/schemas/')
                  schema_name = subschema_ref.delete_prefix('#/components/schemas/')
                  subschemas_by_schema_name[schema_name] = subschema if FIXED_FIELD_REGEX.match?(schema_name)
                end
              end

              explicit_mapping = mapping.transform_values do |schema_name_or_ref|
                subschemas_by_schema_name.fetch(schema_name_or_ref) { subschemas_by_ref.fetch(schema_name_or_ref) }
              end

              implicit_mapping = subschemas_by_schema_name.reject do |_schema_name, subschema|
                explicit_mapping.value?(subschema)
              end

              implicit_mapping.merge(explicit_mapping)
            else
              Hash.new do |hash, property_value|
                schema_name_or_ref = mapping.fetch(property_value, property_value)

                subschema = nil

                if FIXED_FIELD_REGEX.match?(schema_name_or_ref)
                  subschema = begin
                    schema.ref("#/components/schemas/#{schema_name_or_ref}")
                  rescue InvalidRefPointer
                    nil
                  end
                end

                subschema ||= begin
                  schema.ref(schema_name_or_ref)
                rescue InvalidRefResolution, UnknownRef
                  nil
                end

                hash[property_value] = subschema
              end
            end
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, false) unless instance.is_a?(Hash)

            property_name = value.fetch('propertyName')

            return result(instance, instance_location, keyword_location, false) unless instance.key?(property_name)

            property_value = instance.fetch(property_name)
            subschema = subschemas_by_property_value[property_value]

            return result(instance, instance_location, keyword_location, false) unless subschema

            return if skip_ref_once == subschema.absolute_keyword_location
            subschema.parsed['allOf']&.skip_ref_once = schema.absolute_keyword_location

            subschema_result = subschema.validate_instance(instance, instance_location, keyword_location, context)

            result(instance, instance_location, keyword_location, subschema_result.valid, subschema_result.nested)
          ensure
            self.skip_ref_once = nil
          end
        end
      end
    end
  end
end
