require 'pact_broker/string_refinements'

module PactBroker
  module HashRefinements

    refine Hash do
      using PactBroker::StringRefinements

      def deep_merge(other_hash, &block)
        block_actual = Proc.new {|key, oldval, newval|
            newval = block.call(key, oldval, newval) if block_given?
            [oldval, newval].all? {|v| v.is_a?(Hash)} ? oldval.merge(newval, &block_actual) : newval
        }
        merge(other_hash, &block_actual)
      end

      def symbolize_keys
        symbolize_keys_private(self)
      end

      def stringify_keys
        stringify_keys_private(self)
      end

      def snakecase_keys
        snakecase_keys_private(self)
      end

      def slice(*keys)
        keys.each_with_object(Hash.new) { |k, hash| hash[k] = self[k] if has_key?(k) }
      end

      def without(*keys)
        reject { |k,_| keys.include?(k) }
      end

      def camelcase_keys
        camelcase_keys_private(self)
      end

      private

      def snakecase_keys_private(params)
        case params
        when Hash
          params.inject({}) do |result, (key, value)|
            snake_key = case key
            when String then key.snakecase
            when Symbol then key.to_s.snakecase.to_sym
            else
              key
                        end
            result.merge(snake_key => snakecase_keys_private(value))
          end
        when Array
          params.collect { |value| snakecase_keys_private(value) }
        else
          params
        end
      end

      def camelcase_keys_private(params)
        case params
        when Hash
          params.inject({}) do |result, (key, value)|
            snake_key = case key
            when String then key.camelcase
            when Symbol then key.to_s.camelcase.to_sym
            else
              key
                        end
            result.merge(snake_key => camelcase_keys_private(value))
          end
        when Array
          params.collect { |value| camelcase_keys_private(value) }
        else
          params
        end
      end

      def symbolize_keys_private(params)
        case params
        when Hash
          params.inject({}) do |result, (key, value)|
            result.merge(key.to_sym => symbolize_keys_private(value))
          end
        when Array
          params.collect { |value| symbolize_keys_private(value) }
        else
          params
        end
      end

      def stringify_keys_private(params)
        case params
        when Hash
          params.inject({}) do |result, (key, value)|
            result.merge(key.to_s => symbolize_keys_private(value))
          end
        when Array
          params.collect { |value| symbolize_keys_private(value) }
        else
          params
        end
      end
    end
  end
end
