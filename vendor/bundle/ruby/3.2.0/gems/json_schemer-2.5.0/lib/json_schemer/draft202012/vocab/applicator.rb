# frozen_string_literal: true
module JSONSchemer
  module Draft202012
    module Vocab
      module Applicator
        class AllOf < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} does not match all `allOf` schemas"
          end

          def parse
            value.map.with_index do |subschema, index|
              subschema(subschema, index.to_s)
            end
          end

          def validate(instance, instance_location, keyword_location, context)
            nested = parsed.map.with_index do |subschema, index|
              subschema.validate_instance(instance, instance_location, join_location(keyword_location, index.to_s), context)
            end
            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested)
          end
        end

        class AnyOf < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} does not match any `anyOf` schemas"
          end

          def parse
            value.map.with_index do |subschema, index|
              subschema(subschema, index.to_s)
            end
          end

          def validate(instance, instance_location, keyword_location, context)
            nested = parsed.map.with_index do |subschema, index|
              subschema.validate_instance(instance, instance_location, join_location(keyword_location, index.to_s), context)
            end
            result(instance, instance_location, keyword_location, nested.any?(&:valid), nested)
          end
        end

        class OneOf < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} does not match exactly one `oneOf` schema"
          end

          def parse
            value.map.with_index do |subschema, index|
              subschema(subschema, index.to_s)
            end
          end

          def validate(instance, instance_location, keyword_location, context)
            nested = parsed.map.with_index do |subschema, index|
              subschema.validate_instance(instance, instance_location, join_location(keyword_location, index.to_s), context)
            end
            valid_count = nested.count(&:valid)
            result(instance, instance_location, keyword_location, valid_count == 1, nested, :ignore_nested => valid_count > 1)
          end
        end

        class Not < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} matches `not` schema"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            subschema_result = parsed.validate_instance(instance, instance_location, keyword_location, context)
            result(instance, instance_location, keyword_location, !subschema_result.valid, subschema_result.nested)
          end
        end

        class If < Keyword
          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            subschema_result = parsed.validate_instance(instance, instance_location, keyword_location, context)
            result(instance, instance_location, keyword_location, true, subschema_result.nested, :annotation => subschema_result.valid)
          end
        end

        class Then < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} does not match conditional `then` schema"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            return unless context.adjacent_results.key?(If) && context.adjacent_results.fetch(If).annotation
            subschema_result = parsed.validate_instance(instance, instance_location, keyword_location, context)
            result(instance, instance_location, keyword_location, subschema_result.valid, subschema_result.nested)
          end
        end

        class Else < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} does not match conditional `else` schema"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            return unless context.adjacent_results.key?(If) && !context.adjacent_results.fetch(If).annotation
            subschema_result = parsed.validate_instance(instance, instance_location, keyword_location, context)
            result(instance, instance_location, keyword_location, subschema_result.valid, subschema_result.nested)
          end
        end

        class DependentSchemas < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} does not match applicable `dependentSchemas` schemas"
          end

          def parse
            value.each_with_object({}) do |(key, subschema), out|
              out[key] = subschema(subschema, key)
            end
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Hash)

            nested = parsed.select do |key, _subschema|
              instance.key?(key)
            end.map do |key, subschema|
              subschema.validate_instance(instance, instance_location, join_location(keyword_location, key), context)
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested)
          end
        end

        class PrefixItems < Keyword
          def error(formatted_instance_location:, **)
            "array items at #{formatted_instance_location} do not match corresponding `prefixItems` schemas"
          end

          def parse
            value.map.with_index do |subschema, index|
              subschema(subschema, index.to_s)
            end
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Array)

            nested = instance.take(parsed.size).map.with_index do |item, index|
              parsed.fetch(index).validate_instance(item, join_location(instance_location, index.to_s), join_location(keyword_location, index.to_s), context)
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested, :annotation => (nested.size - 1))
          end
        end

        class Items < Keyword
          def error(formatted_instance_location:, **)
            "array items at #{formatted_instance_location} do not match `items` schema"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Array)

            evaluated_index = context.adjacent_results[PrefixItems]&.annotation
            offset = evaluated_index ? (evaluated_index + 1) : 0

            nested = instance.slice(offset..-1).map.with_index do |item, index|
              parsed.validate_instance(item, join_location(instance_location, (offset + index).to_s), keyword_location, context)
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested, :annotation => nested.any?)
          end
        end

        class Contains < Keyword
          def error(formatted_instance_location:, **)
            "array at #{formatted_instance_location} does not contain enough items that match `contains` schema"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Array)

            nested = instance.map.with_index do |item, index|
              parsed.validate_instance(item, join_location(instance_location, index.to_s), keyword_location, context)
            end

            annotation = []
            nested.each_with_index do |nested_result, index|
              annotation << index if nested_result.valid
            end

            min_contains = schema.parsed['minContains']&.parsed || 1

            result(instance, instance_location, keyword_location, annotation.size >= min_contains, nested, :annotation => annotation, :ignore_nested => true)
          end
        end

        class Properties < Keyword
          def error(formatted_instance_location:, **)
            "object properties at #{formatted_instance_location} do not match corresponding `properties` schemas"
          end

          def parse
            value.each_with_object({}) do |(property, subschema), out|
              out[property] = subschema(subschema, property)
            end
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Hash)

            if root.before_property_validation.any?
              original_instance = context.original_instance(instance_location)
              root.before_property_validation.each do |hook|
                parsed.each do |property, subschema|
                  hook.call(original_instance, property, subschema.value, schema.value)
                end
              end
              instance.replace(deep_stringify_keys(original_instance))
            end

            evaluated_keys = []
            nested = []

            parsed.each do |property, subschema|
              if instance.key?(property)
                evaluated_keys << property
                nested << subschema.validate_instance(instance.fetch(property), join_location(instance_location, property), join_location(keyword_location, property), context)
              end
            end

            if root.after_property_validation.any?
              original_instance = context.original_instance(instance_location)
              root.after_property_validation.each do |hook|
                parsed.each do |property, subschema|
                  hook.call(original_instance, property, subschema.value, schema.value)
                end
              end
              instance.replace(deep_stringify_keys(original_instance))
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested, :annotation => evaluated_keys)
          end
        end

        class PatternProperties < Keyword
          def error(formatted_instance_location:, **)
            "object properties at #{formatted_instance_location} do not match corresponding `patternProperties` schemas"
          end

          def parse
            value.each_with_object({}) do |(pattern, subschema), out|
              out[pattern] = subschema(subschema, pattern)
            end
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Hash)

            evaluated = Set[]
            nested = []

            parsed.each do |pattern, subschema|
              regexp = root.resolve_regexp(pattern)
              instance.each do |key, value|
                if regexp.match?(key)
                  evaluated << key
                  nested << subschema.validate_instance(value, join_location(instance_location, key), join_location(keyword_location, pattern), context)
                end
              end
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested, :annotation => evaluated.to_a)
          end
        end

        class AdditionalProperties < Keyword
          def error(formatted_instance_location:, **)
            "object properties at #{formatted_instance_location} do not match `additionalProperties` schema"
          end

          def false_schema_error(formatted_instance_location:, **)
            "object property at #{formatted_instance_location} is a disallowed additional property"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Hash)

            evaluated_keys = context.adjacent_results[Properties]&.annotation || []
            evaluated_keys += context.adjacent_results[PatternProperties]&.annotation || []
            evaluated_keys = evaluated_keys.to_set

            evaluated = instance.reject do |key, _value|
              evaluated_keys.include?(key)
            end

            nested = evaluated.map do |key, value|
              parsed.validate_instance(value, join_location(instance_location, key), keyword_location, context)
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested, :annotation => evaluated.keys)
          end
        end

        class PropertyNames < Keyword
          def error(formatted_instance_location:, **)
            "object property names at #{formatted_instance_location} do not match `propertyNames` schema"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Hash)

            nested = instance.map do |key, _value|
              parsed.validate_instance(key, instance_location, keyword_location, context)
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested)
          end
        end

        class Dependencies < Keyword
          def error(formatted_instance_location:, **)
            "object at #{formatted_instance_location} either does not match applicable `dependencies` schemas or is missing required `dependencies` properties"
          end

          def parse
            value.each_with_object({}) do |(key, value), out|
              out[key] = value.is_a?(Array) ? value : subschema(value, key)
            end
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Hash)

            existing_keys = instance.keys

            nested = parsed.select do |key, _value|
              instance.key?(key)
            end.map do |key, value|
              if value.is_a?(Array)
                missing_keys = value - existing_keys
                result(instance, instance_location, join_location(keyword_location, key), missing_keys.none?, :details => { 'missing_keys' => missing_keys })
              else
                value.validate_instance(instance, instance_location, join_location(keyword_location, key), context)
              end
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested)
          end
        end
      end
    end
  end
end
