# frozen_string_literal: true
module JSONSchemer
  module Draft202012
    module Vocab
      module MetaData
        class ReadOnly < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} is `readOnly`"
          end

          def validate(instance, instance_location, keyword_location, context)
            valid = parsed != true || !context.access_mode || context.access_mode == 'read'
            result(instance, instance_location, keyword_location, valid, :annotation => value)
          end
        end

        class WriteOnly < Keyword
          def error(formatted_instance_location:, **)
            "value at #{formatted_instance_location} is `writeOnly`"
          end

          def validate(instance, instance_location, keyword_location, context)
            valid = parsed != true || !context.access_mode || context.access_mode == 'write'
            result(instance, instance_location, keyword_location, valid, :annotation => value)
          end
        end
      end
    end
  end
end
