# frozen_string_literal: true
module JSONSchemer
  module Draft202012
    module Vocab
      module Content
        class ContentEncoding < Keyword
          def parse
            root.fetch_content_encoding(value) { raise UnknownContentEncoding, value }
          end

          def validate(instance, instance_location, keyword_location, _context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(String)

            _valid, annotation = parsed.call(instance)

            result(instance, instance_location, keyword_location, true, :annotation => annotation)
          end
        end

        class ContentMediaType < Keyword
          def parse
            root.fetch_content_media_type(value) { raise UnknownContentMediaType, value }
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless instance.is_a?(String)

            decoded_instance = context.adjacent_results[ContentEncoding]&.annotation || instance
            _valid, annotation = parsed.call(decoded_instance)

            result(instance, instance_location, keyword_location, true, :annotation => annotation)
          end
        end

        class ContentSchema < Keyword
          def parse
            subschema(value)
          end

          def validate(instance, instance_location, keyword_location, context)
            return result(instance, instance_location, keyword_location, true) unless context.adjacent_results.key?(ContentMediaType)

            parsed_instance = context.adjacent_results.fetch(ContentMediaType).annotation
            annotation = parsed.validate_instance(parsed_instance, instance_location, keyword_location, context)

            result(instance, instance_location, keyword_location, true, :annotation => annotation.to_output_unit)
          end
        end
      end
    end
  end
end
