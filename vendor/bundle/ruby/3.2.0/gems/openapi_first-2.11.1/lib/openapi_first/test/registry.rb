# frozen_string_literal: true

module OpenapiFirst
  module Test
    class NotRegisteredError < Error; end
    class AlreadyRegisteredError < Error; end

    # @visibility private
    module Registry
      def definitions
        @definitions ||= {}
      end

      # Register an OpenAPI definition for testing
      # @param path_or_definition [String, Definition] Path to the OpenAPI file or a Definition object
      # @param as [Symbol] Name to register the API definition as
      def register(path_or_definition, as: :default)
        if definitions.key?(as) && as == :default
          raise(
            AlreadyRegisteredError,
            "#{definitions[as].filepath.inspect} is already registered " \
            "as ':default' so you cannot register #{path_or_definition.inspect} without " \
            'giving it a custom name. Please call register with a custom key like: ' \
            "#{name}.register(#{path_or_definition.inspect}, as: :my_other_api)"
          )
        end

        definition = OpenapiFirst.load(path_or_definition)
        definitions[as] = definition
        definition
      end

      def [](api)
        definitions.fetch(api) do
          option = api == :default ? '' : ", as: #{api.inspect}"
          raise(NotRegisteredError,
                "API description '#{api.inspect}' not found." \
                "Please call #{name}.register('myopenapi.yaml'#{option}) " \
                'once before running tests.')
        end
      end
    end
  end
end
