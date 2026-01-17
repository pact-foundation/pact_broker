# frozen_string_literal: true
module JSONSchemer
  module Draft201909
    module Vocab
      module Core
        class RecursiveAnchor < Keyword
          def parse
            root.resources[:dynamic][schema.base_uri] = schema if value == true
            value
          end
        end

        class RecursiveRef < Keyword
          def ref_uri
            @ref_uri ||= URI.join(schema.base_uri, value)
          end

          def ref_schema
            @ref_schema ||= root.resolve_ref(ref_uri)
          end

          def recursive_anchor
            return @recursive_anchor if defined?(@recursive_anchor)
            @recursive_anchor = (ref_schema.parsed['$recursiveAnchor']&.parsed == true)
          end

          def validate(instance, instance_location, keyword_location, context)
            schema = ref_schema

            if recursive_anchor
              context.dynamic_scope.each do |ancestor|
                if ancestor.root.resources.fetch(:dynamic).key?(ancestor.base_uri)
                  schema = ancestor.root.resources.fetch(:dynamic).fetch(ancestor.base_uri)
                  break
                end
              end
            end

            schema.validate_instance(instance, instance_location, keyword_location, context)
          end
        end
      end
    end
  end
end
