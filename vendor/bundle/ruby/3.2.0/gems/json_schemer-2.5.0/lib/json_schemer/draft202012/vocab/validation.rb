# frozen_string_literal: true
module JSONSchemer
  module Draft202012
    module Vocab
      module Validation
        class Type < Keyword
          def self.valid_integer?(instance)
            instance.is_a?(Numeric) && (instance.is_a?(Integer) || instance.floor == instance)
          end

          def error(formatted_instance_location:, **)
            case value
            when 'null'
              "value at #{formatted_instance_location} is not null"
            when 'boolean'
              "value at #{formatted_instance_location} is not a boolean"
            when 'number'
              "value at #{formatted_instance_location} is not a number"
            when 'integer'
              "value at #{formatted_instance_location} is not an integer"
            when 'string'
              "value at #{formatted_instance_location} is not a string"
            when 'array'
              "value at #{formatted_instance_location} is not an array"
            when 'object'
              "value at #{formatted_instance_location} is not an object"
            else
              "value at #{formatted_instance_location} is not one of the types: #{value}"
            end
          end

          def validate(instance, instance_location, keyword_location, _context)
            case parsed
            when String
              result(instance, instance_location, keyword_location, valid_type(parsed, instance), :type => parsed)
            when Array
              result(instance, instance_location, keyword_location, parsed.any? { |type| valid_type(type, instance) })
            end
          end

        private

          def valid_type(type, instance)
            case type
            when 'null'
              instance.nil?
            when 'boolean'
              instance == true || instance == false
            when 'number'
              instance.is_a?(Numeric)
            when 'integer'
              self.class.valid_integer?(instance)
            when 'string'
              instance.is_a?(String)
            when 'array'
              instance.is_a?(Array)
            when 'object'
              instance.is_a?(Hash)
            else
              true
            end
          end
        end

        class Enum < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} is not one of: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !value || value.include?(instance))
          end
        end

        class Const < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} is not: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, value == instance)
          end
        end

        class MultipleOf < Keyword
          def error(formatted_instance_location:, **)
            "number at #{formatted_instance_location} is not a multiple of: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Numeric) || BigDecimal(instance.to_s).modulo(value).zero?)
          end
        end

        class Maximum < Keyword
          def error(formatted_instance_location:, **)
            "number at #{formatted_instance_location} is greater than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Numeric) || instance <= value)
          end
        end

        class ExclusiveMaximum < Keyword
          def error(formatted_instance_location:, **)
            "number at #{formatted_instance_location} is greater than or equal to: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Numeric) || instance < value)
          end
        end

        class Minimum < Keyword
          def error(formatted_instance_location:, **)
            "number at #{formatted_instance_location} is less than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Numeric) || instance >= value)
          end
        end

        class ExclusiveMinimum < Keyword
          def error(formatted_instance_location:, **)
            "number at #{formatted_instance_location} is less than or equal to: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Numeric) || instance > value)
          end
        end

        class MaxLength < Keyword
          def error(formatted_instance_location:, **)
            "string length at #{formatted_instance_location} is greater than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(String) || instance.size <= value)
          end
        end

        class MinLength < Keyword
          def error(formatted_instance_location:, **)
            "string length at #{formatted_instance_location} is less than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(String) || instance.size >= value)
          end
        end

        class Pattern < Keyword
          def error(formatted_instance_location:, **)
            "string at #{formatted_instance_location} does not match pattern: #{value}"
          end

          def parse
            root.resolve_regexp(value)
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(String) || parsed.match?(instance))
          end
        end

        class MaxItems < Keyword
          def error(formatted_instance_location:, **)
            "array size at #{formatted_instance_location} is greater than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Array) || instance.size <= value)
          end
        end

        class MinItems < Keyword
          def error(formatted_instance_location:, **)
            "array size at #{formatted_instance_location} is less than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Array) || instance.size >= value)
          end
        end

        class UniqueItems < Keyword
          def error(formatted_instance_location:, **)
            "array items at #{formatted_instance_location} are not unique"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Array) || value == false || instance.size == instance.uniq.size)
          end
        end

        class MaxContains < Keyword
          def error(formatted_instance_location:, **)
            "number of array items at #{formatted_instance_location} matching `contains` schema is greater than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Array) && context.adjacent_results.key?(Applicator::Contains)
            evaluated_items = context.adjacent_results.fetch(Applicator::Contains).annotation
            result(instance, instance_location, keyword_location, evaluated_items.size <= value)
          end
        end

        class MinContains < Keyword
          def error(formatted_instance_location:, **)
            "number of array items at #{formatted_instance_location} matching `contains` schema is less than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Array) && context.adjacent_results.key?(Applicator::Contains)
            evaluated_items = context.adjacent_results.fetch(Applicator::Contains).annotation
            result(instance, instance_location, keyword_location, evaluated_items.size >= value)
          end
        end

        class MaxProperties < Keyword
          def error(formatted_instance_location:, **)
            "object size at #{formatted_instance_location} is greater than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Hash) || instance.size <= value)
          end
        end

        class MinProperties < Keyword
          def error(formatted_instance_location:, **)
            "object size at #{formatted_instance_location} is less than: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, !instance.is_a?(Hash) || instance.size >= value)
          end
        end

        class Required < Keyword
          def error(formatted_instance_location:, details:, **)
            "object at #{formatted_instance_location} is missing required properties: #{details.fetch('missing_keys').join(', ')}"
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Hash)

            required_keys = value

            if context.access_mode && schema.parsed.key?('properties')
              inapplicable_access_mode_keys = []
              schema.parsed.fetch('properties').parsed.each do |property, subschema|
                read_only, write_only = subschema.parsed.values_at('readOnly', 'writeOnly')
                inapplicable_access_mode_keys << property if context.access_mode == 'write' && read_only&.parsed == true
                inapplicable_access_mode_keys << property if context.access_mode == 'read' && write_only&.parsed == true
              end
              required_keys -= inapplicable_access_mode_keys
            end

            missing_keys = required_keys - instance.keys
            result(instance, instance_location, keyword_location, missing_keys.none?, :details => { 'missing_keys' => missing_keys })
          end
        end

        class DependentRequired < Keyword
          def error(formatted_instance_location:, **)
            "object at #{formatted_instance_location} is missing required `dependentRequired` properties"
          end

          def validate(instance, instance_location, keyword_location, _context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(Hash)

            existing_keys = instance.keys

            nested = value.select do |key, _required_keys|
              instance.key?(key)
            end.map do |key, required_keys|
              result(instance, join_location(instance_location, key), join_location(keyword_location, key), (required_keys - existing_keys).none?)
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested)
          end
        end
      end
    end
  end
end
