# frozen_string_literal: true
module JSONSchemer
  CATCHALL = '*'
  I18N_SEPARATOR = "\x1F" # unit separator
  I18N_SCOPE = 'json_schemer'
  I18N_ERRORS_SCOPE = "#{I18N_SCOPE}#{I18N_SEPARATOR}errors"
  X_ERROR_REGEX = /%\{(instance|instanceLocation|formattedInstanceLocation|keywordValue|keywordLocation|absoluteKeywordLocation|details|details__\w+)\}/
  CLASSIC_ERROR_TYPES = Hash.new do |hash, klass|
    hash[klass] = klass.name.rpartition('::').last.sub(/\A[[:alpha:]]/, &:downcase)
  end

  Result = Struct.new(:source, :instance, :instance_location, :keyword_location, :valid, :nested, :type, :annotation, :details, :ignore_nested, :nested_key) do
    def output(output_format)
      case output_format
      when 'classic'
        classic
      when 'flag'
        flag
      when 'basic'
        basic
      when 'detailed'
        detailed
      when 'verbose'
        verbose
      else
        raise UnknownOutputFormat, output_format
      end
    end

    def error
      return @error if defined?(@error)
      if source.x_error
        x_error_replacements = interpolation_variables.transform_keys { |key| "%{#{key}}" }
        # not using sprintf because it warns: "too many arguments for format string"
        @error = source.x_error.gsub(X_ERROR_REGEX, x_error_replacements)
        @x_error = true
      else
        @error = source.error(:formatted_instance_location => formatted_instance_location, :details => details)
        if i18n?
          begin
            @error = i18n!
            @i18n = true
          rescue I18n::MissingTranslationData
          end
        end
      end
      @error
    end

    def i18n?
      return @@i18n if defined?(@@i18n)
      @@i18n = defined?(I18n) && I18n.exists?(I18N_SCOPE)
    end

    def i18n!
      base_uri_str = source.schema.base_uri.to_s
      meta_schema_base_uri_str = source.schema.meta_schema.base_uri.to_s
      error_key = source.error_key
      I18n.translate!(
        source.absolute_keyword_location,
        :default => [
          "#{base_uri_str}#{I18N_SEPARATOR}##{resolved_keyword_location}",
          "##{resolved_keyword_location}",
          "#{base_uri_str}#{I18N_SEPARATOR}#{error_key}",
          "#{base_uri_str}#{I18N_SEPARATOR}#{CATCHALL}",
          "#{meta_schema_base_uri_str}#{I18N_SEPARATOR}#{error_key}",
          "#{meta_schema_base_uri_str}#{I18N_SEPARATOR}#{CATCHALL}",
          error_key,
          CATCHALL
        ].map!(&:to_sym),
        :separator => I18N_SEPARATOR,
        :scope => I18N_ERRORS_SCOPE,
        **interpolation_variables
      )
    end

    def to_output_unit
      out = {
        'valid' => valid,
        'keywordLocation' => resolved_keyword_location,
        'absoluteKeywordLocation' => source.absolute_keyword_location,
        'instanceLocation' => resolved_instance_location
      }
      if valid
        out['annotation'] = annotation if annotation
      else
        out['error'] = error
        out['x-error'] = true if @x_error
        out['i18n'] = true if @i18n
      end
      out
    end

    def to_classic
      schema = source.schema
      out = {
        'data' => instance,
        'data_pointer' => resolved_instance_location,
        'schema' => schema.value,
        'schema_pointer' => schema.schema_pointer,
        'root_schema' => schema.root.value,
        'type' => type || CLASSIC_ERROR_TYPES[source.class]
      }
      out['error'] = error
      out['x-error'] = true if @x_error
      out['i18n'] = true if @i18n
      out['details'] = details if details
      out
    end

    def flag
      { 'valid' => valid }
    end

    def basic
      out = to_output_unit
      if nested&.any?
        out[nested_key] = Enumerator.new do |yielder|
          results = [self]
          while result = results.pop
            if result.ignore_nested || !result.nested&.any?
              yielder << result.to_output_unit
            else
              previous_results_size = results.size
              result.nested.reverse_each do |nested_result|
                results << nested_result if nested_result.valid == valid
              end
              yielder << result.to_output_unit unless (results.size - previous_results_size) == 1
            end
          end
        end
      end
      out
    end

    def detailed
      return to_output_unit if ignore_nested || !nested&.any?
      matching_results = nested.select { |nested_result| nested_result.valid == valid }
      if matching_results.size == 1
        matching_results.first.detailed
      else
        out = to_output_unit
        if matching_results.any?
          out[nested_key] = Enumerator.new do |yielder|
            matching_results.each { |nested_result| yielder << nested_result.detailed }
          end
        end
        out
      end
    end

    def verbose
      out = to_output_unit
      if nested&.any?
        out[nested_key] = Enumerator.new do |yielder|
          nested.each { |nested_result| yielder << nested_result.verbose }
        end
      end
      out
    end

    def classic
      Enumerator.new do |yielder|
        unless valid
          results = [self]
          while result = results.pop
            if result.ignore_nested || !result.nested&.any?
              yielder << result.to_classic
            else
              previous_results_size = results.size
              result.nested.reverse_each do |nested_result|
                results << nested_result if nested_result.valid == valid
              end
              yielder << result.to_classic if (results.size - previous_results_size) == 0
            end
          end
        end
      end
    end

    def insert_property_defaults(context)
      instance_locations = {}
      instance_locations.compare_by_identity

      results = [[self, true]]
      while (result, valid = results.pop)
        next if result.source.is_a?(Schema::NOT_KEYWORD_CLASS)

        valid &&= result.valid
        result.nested&.each { |nested_result| results << [nested_result, valid] }

        if result.source.is_a?(Schema::PROPERTIES_KEYWORD_CLASS) && result.instance.is_a?(Hash)
          result.source.parsed.each do |property, schema|
            next if result.instance.key?(property)
            next unless default = default_keyword_instance(schema)
            instance_location = Location.join(result.instance_location, property)
            keyword_location = Location.join(Location.join(result.keyword_location, property), default.keyword)
            default_result = default.validate(nil, instance_location, keyword_location, nil)
            instance_locations[result.instance_location] ||= {}
            instance_locations[result.instance_location][property] ||= []
            instance_locations[result.instance_location][property] << [default_result, valid]
          end
        end
      end

      inserted = false

      instance_locations.each do |instance_location, properties|
        original_instance = context.original_instance(instance_location)
        properties.each do |property, results_with_tree_validity|
          property_inserted = yield(original_instance, property, results_with_tree_validity)
          inserted ||= (property_inserted != false)
        end
      end

      inserted
    end

  private

    def resolved_instance_location
      @resolved_instance_location ||= Location.resolve(instance_location)
    end

    def formatted_instance_location
      @formatted_instance_location ||= resolved_instance_location.empty? ? 'root' : "`#{resolved_instance_location}`"
    end

    def resolved_keyword_location
      @resolved_keyword_location ||= Location.resolve(keyword_location)
    end

    def default_keyword_instance(schema)
      schema.parsed.fetch('default') do
        schema.parsed.find do |_keyword, keyword_instance|
          next unless keyword_instance.respond_to?(:ref_schema)
          next unless default = default_keyword_instance(keyword_instance.ref_schema)
          break default
        end
      end
    end

    def interpolation_variables
      interpolation_variables = {
        :instance => instance,
        :instanceLocation => resolved_instance_location,
        :formattedInstanceLocation => formatted_instance_location,
        :keywordValue => source.value,
        :keywordLocation => resolved_keyword_location,
        :absoluteKeywordLocation => source.absolute_keyword_location,
        :details => details,
      }
      details&.each do |key, value|
        interpolation_variables["details__#{key}".to_sym] = value
      end
      interpolation_variables
    end
  end
end
