# frozen_string_literal: true
module JSONSchemer
  module Draft7
    module Vocab
      module Validation
        class Ref < Draft202012::Vocab::Core::Ref
          def self.exclusive?
            true
          end
        end

        class AdditionalItems < Keyword
          def error(formatted_instance_location:, **)
            "array items at #{formatted_instance_location} do not match `additionalItems` schema"
          end

          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            items = schema.parsed['items']&.parsed

            if !instance.is_a?(Array) || !items.is_a?(Array) || items.size >= instance.size
              return result(instance, instance_location, keyword_location, true)
            end

            offset = items.size

            nested = instance.slice(offset..-1).map.with_index do |item, index|
              parsed.validate_instance(item, join_location(instance_location, (offset + index).to_s), keyword_location, context)
            end

            result(instance, instance_location, keyword_location, nested.all?(&:valid), nested, :annotation => nested.any?)
          end
        end

        class ContentEncoding < Draft202012::Vocab::Content::ContentEncoding
          def error(formatted_instance_location:, **)
            "string at #{formatted_instance_location} could not be decoded using encoding: #{value}"
          end

          def validate(instance, instance_location, keyword_location, _context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(String)

            valid, annotation = parsed.call(instance)

            result(instance, instance_location, keyword_location, valid, :annotation => annotation)
          end
        end

        class ContentMediaType < Draft202012::Vocab::Content::ContentMediaType
          def error(formatted_instance_location:, **)
            "string at #{formatted_instance_location} could not be parsed using media type: #{value}"
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(String)

            decoded_instance = context.adjacent_results[ContentEncoding]&.annotation || instance
            valid, annotation = parsed.call(decoded_instance)

            result(instance, instance_location, keyword_location, valid, :annotation => annotation)
          end
        end
      end
    end
  end
end
