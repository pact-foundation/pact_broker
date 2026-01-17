# frozen_string_literal: true
module JSONSchemer
  module Draft202012
    module Vocab
      module Core
        class Schema < Keyword
          def parse
            schema.meta_schema = if value == schema.base_uri.to_s
              schema
            else
              META_SCHEMAS_BY_BASE_URI_STR[value] || root.resolve_ref(URI(value))
            end
            value
          end
        end

        class Vocabulary < Keyword
          def parse
            value.each_with_object({}) do |(vocabulary, required), out|
              if VOCABULARIES.key?(vocabulary)
                out[vocabulary] = VOCABULARIES.fetch(vocabulary)
              elsif required
                raise UnknownVocabulary, vocabulary
              end
            end.tap do |vocabularies|
              schema.keywords = vocabularies.sort_by do |vocabulary, _keywords|
                VOCABULARY_ORDER.fetch(vocabulary, Float::INFINITY)
              end.each_with_object({}) do |(_vocabulary, keywords), out|
                out.merge!(keywords)
              end
              schema.keyword_order = schema.keywords.transform_values.with_index { |_keyword_class, index| index }
            end
          end
        end

        class Id < Keyword
          def parse
            URI.join(schema.base_uri, value).tap do |uri|
              schema.base_uri = uri
              root.resources[:lexical][uri] = schema
            end
          end
        end

        class Anchor < Keyword
          def parse
            URI.join(schema.base_uri, "##{value}").tap do |uri|
              root.resources[:lexical][uri] = schema
            end
          end
        end

        class Ref < Keyword
          def self.exclusive?
            false
          end

          def ref_uri
            @ref_uri ||= URI.join(schema.base_uri, value)
          end

          def ref_schema
            @ref_schema ||= root.resolve_ref(ref_uri)
          end

          def validate(instance, instance_location, keyword_location, context)
            ref_schema.validate_instance(instance, instance_location, keyword_location, context)
          end
        end

        class DynamicAnchor < Keyword
          def parse
            URI.join(schema.base_uri, "##{value}").tap do |uri|
              root.resources[:lexical][uri] = schema
              root.resources[:dynamic][uri] = schema
            end
          end
        end

        class DynamicRef < Keyword
          def ref_uri
            @ref_uri ||= URI.join(schema.base_uri, value)
          end

          def ref_schema
            @ref_schema ||= root.resolve_ref(ref_uri)
          end

          def dynamic_anchor
            return @dynamic_anchor if defined?(@dynamic_anchor)
            fragment = ref_schema.parsed['$dynamicAnchor']&.parsed&.fragment
            @dynamic_anchor = (fragment == ref_uri.fragment ? fragment : nil)
          end

          def validate(instance, instance_location, keyword_location, context)
            schema = ref_schema

            if dynamic_anchor
              context.dynamic_scope.each do |ancestor|
                dynamic_uri = URI.join(ancestor.base_uri, "##{dynamic_anchor}")
                if ancestor.root.resources.fetch(:dynamic).key?(dynamic_uri)
                  schema = ancestor.root.resources.fetch(:dynamic).fetch(dynamic_uri)
                  break
                end
              end
            end

            schema.validate_instance(instance, instance_location, keyword_location, context)
          end
        end

        class Defs < Keyword
          def parse
            value.each_with_object({}) do |(key, subschema), out|
              out[key] = subschema(subschema, key)
            end
          end
        end

        class Comment < Keyword; end

        class XError < Keyword
          def message(error_key)
            value.is_a?(Hash) ? (value[error_key] || value[CATCHALL]) : value
          end
        end

        class UnknownKeyword < Keyword
          def parse
            if value.is_a?(Hash)
              {}
            elsif value.is_a?(Array)
              []
            else
              value
            end
          end

          def fetch(token)
            if value.is_a?(Hash)
              parsed[token] ||= JSONSchemer::Schema::UNKNOWN_KEYWORD_CLASS.new(value.fetch(token), self, token, schema)
            elsif value.is_a?(Array)
              parsed[token.to_i] ||= JSONSchemer::Schema::UNKNOWN_KEYWORD_CLASS.new(value.fetch(token.to_i), self, token, schema)
            else
              raise KeyError.new(:receiver => parsed, :key => token)
            end
          end

          def parsed_schema
            @parsed_schema ||= subschema(value)
          end

          def validate(instance, instance_location, keyword_location, _context)
            result(instance, instance_location, keyword_location, true, :annotation => value)
          end
        end
      end
    end
  end
end
