# frozen_string_literal: true
module JSONSchemer
  module Draft202012
    module Vocab
      module Unevaluated
        class UnevaluatedItems < Keyword
          def error(formatted_instance_location:, **)
            "array items at #{formatted_instance_location} do not match `unevaluatedItems` schema"
          end

          def false_schema_error(formatted_instance_location:, **)
            "array item at #{formatted_instance_location} is a disallowed unevaluated item"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Array)

            unevaluated_items = instance.size.times.to_set

            context.adjacent_results.each_value do |adjacent_result|
              collect_unevaluated_items(adjacent_result, unevaluated_items)
            end

            nested = unevaluated_items.map do |index|
              parsed.validate_instance(instance.fetch(index), join_location(instance_location, index.to_s), keyword_location, context)
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested, :annotation => nested.any?)
          end

        private

          def collect_unevaluated_items(result, unevaluated_items)
            case result.source
            when Applicator::PrefixItems
              unevaluated_items.subtract(0..result.annotation)
            when Applicator::Items, UnevaluatedItems
              unevaluated_items.clear if result.annotation
            when Applicator::Contains
              unevaluated_items.subtract(result.annotation)
            end
            result.nested&.each do |subresult|
              if subresult.valid && subresult.instance_location == result.instance_location
                collect_unevaluated_items(subresult, unevaluated_items)
              end
            end
          end
        end

        class UnevaluatedProperties < Keyword
          def error(formatted_instance_location:, **)
            "object properties at #{formatted_instance_location} do not match `unevaluatedProperties` schema"
          end

          def false_schema_error(formatted_instance_location:, **)
            "object property at #{formatted_instance_location} is a disallowed unevaluated property"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Hash)

            evaluated_keys = Set[]

            context.adjacent_results.each_value do |adjacent_result|
              collect_evaluated_keys(adjacent_result, evaluated_keys)
            end

            evaluated = instance.reject do |key, _value|
              evaluated_keys.include?(key)
            end

            nested = evaluated.map do |key, value|
              parsed.validate_instance(value, join_location(instance_location, key), keyword_location, context)
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested, :annotation => evaluated.keys)
          end

        private

          def collect_evaluated_keys(result, evaluated_keys)
            case result.source
            when Applicator::Properties, Applicator::PatternProperties, Applicator::AdditionalProperties, UnevaluatedProperties
              evaluated_keys.merge(result.annotation)
            end
            result.nested&.each do |subresult|
              if subresult.valid && subresult.instance_location == result.instance_location
                collect_evaluated_keys(subresult, evaluated_keys)
              end
            end
          end
        end
      end
    end
  end
end
