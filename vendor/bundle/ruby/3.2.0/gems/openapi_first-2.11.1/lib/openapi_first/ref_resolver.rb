# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  # This is here to give traverse an OAD while keeping $refs intact
  # @visibility private
  module RefResolver
    def self.load(filepath)
      contents = OpenapiFirst::FileLoader.load(filepath)
      self.for(contents, filepath:)
    end

    def self.for(value, filepath: nil, context: value)
      case value
      when ::Hash
        resolver = Hash.new(value, context:, filepath:)
        if value.key?('$ref')
          probe = resolver.resolve_ref(value['$ref'])
          return probe if probe.is_a?(Array)
        end
        resolver
      when ::Array
        Array.new(value, context:, filepath:)
      when ::NilClass
        nil
      else
        Simple.new(value)
      end
    end

    # @visibility private
    module Diggable
      def dig(*keys)
        keys.inject(self) do |result, key|
          break unless result.respond_to?(:[])

          result[key]
        end
      end
    end

    # @visibility private
    module Resolvable
      def initialize(value, context: value, filepath: nil)
        @value = value
        @context = context
        @filepath = filepath
        @dir = if filepath
                 File.dirname(File.absolute_path(filepath))
               else
                 Dir.pwd
               end
      end

      # The value of this node
      attr_reader :value
      # The path of the file sytem directory where this was loaded from
      attr_reader :dir
      # The object where this node was found in
      attr_reader :context

      attr_reader :filepath

      def ==(_other)
        raise "Don't call == on an unresolved value. Use .value == other instead."
      end

      def resolve_ref(pointer)
        if pointer.start_with?('#')
          value = Hana::Pointer.new(pointer[1..]).eval(context)
          raise "Unknown reference #{pointer} in #{context}" unless value

          return RefResolver.for(value, filepath:, context:)
        end

        relative_path, file_pointer = pointer.split('#')
        full_path = File.expand_path(relative_path, dir)
        return RefResolver.load(full_path) unless file_pointer

        file_contents = FileLoader.load(full_path)
        value = Hana::Pointer.new(file_pointer).eval(file_contents)
        RefResolver.for(value, filepath: full_path, context: file_contents)
      rescue OpenapiFirst::FileNotFoundError => e
        message = "Problem with reference resolving #{pointer.inspect} in " \
                  "file #{File.absolute_path(filepath).inspect}: #{e.message}"
        raise OpenapiFirst::FileNotFoundError, message
      end
    end

    # @visibility private
    class Simple
      include Resolvable

      def resolved = value
    end

    # @visibility private
    class Hash
      include Resolvable
      include Diggable
      include Enumerable

      def ==(_other)
        raise "Don't call == on an unresolved value. Use .value == other instead."
      end

      def resolved
        return resolve_ref(value['$ref']).value if value.key?('$ref')

        value
      end

      def [](key)
        return resolve_ref(@value['$ref'])[key] if !@value.key?(key) && @value.key?('$ref')

        RefResolver.for(@value[key], filepath:, context:)
      end

      def fetch(key)
        return resolve_ref(@value['$ref']).fetch(key) if !@value.key?(key) && @value.key?('$ref')

        RefResolver.for(@value.fetch(key), filepath:, context:)
      end

      def each
        resolved.each_key do |key|
          yield key, self[key]
        end
      end

      # You have to pass configuration or ref_resolver
      def schema(options)
        base_uri = URI::File.build({ path: "#{dir}/" })
        Schema.new(value:, context:, base_uri:, options:)
      end
    end

    # @visibility private
    # Defers initialization JSONSchemer::Schema, because that takes time.
    class Schema
      extend Forwardable

      def initialize(value:, context:, base_uri:, options:)
        @value = value
        @context = context
        @base_uri = base_uri
        @options = options
      end

      attr_reader :value, :context, :base_uri, :options

      def_delegators :schema, :validate, :valid?

      def schema
        @schema ||= begin
          root_schema = JSONSchemer::Schema.new(context, base_uri:, **options)
          JSONSchemer::Schema.new(value, nil, root_schema, base_uri:, **options)
        end
      end
    end

    # @visibility private
    class Array
      include Enumerable
      include Resolvable
      include Diggable

      def [](index)
        item = @value[index]
        return resolve_ref(item['$ref']) if item.is_a?(::Hash) && item.key?('$ref')

        RefResolver.for(item, filepath:, context:)
      end

      def each
        resolved.each_with_index do |_item, index|
          yield self[index]
        end
      end

      def resolved
        value.map do |item|
          if item.respond_to?(:key?) && item.key?('$ref')
            resolve_ref(item['$ref']).resolved
          else
            item
          end
        end
      end
    end
  end
end
