# frozen_string_literal: true

class JsonPath
  class Enumerable
    include ::Enumerable
    include Dig

    def initialize(path, object, mode, options = {})
      @path = path.path
      @object = object
      @mode = mode
      @options = options
    end

    def each(context = @object, key = nil, pos = 0, &blk)
      node = key ? dig_one(context, key) : context
      @_current_node = node
      return yield_value(blk, context, key) if pos == @path.size

      case expr = @path[pos]
      when '*', '..', '@'
        each(context, key, pos + 1, &blk)
      when '$'
        if node == @object
          each(context, key, pos + 1, &blk)
        else
          handle_wildcard(node, "['#{expr}']", context, key, pos, &blk)
        end
      when /^\[(.*)\]$/
        handle_wildcard(node, expr, context, key, pos, &blk)
      when /\(.*\)/
        keys = expr.gsub(/[()]/, '').split(',').map(&:strip)
        new_context = filter_context(context, keys)
        yield_value(blk, new_context, key)
      end

      if pos > 0 && @path[pos - 1] == '..' || (@path[pos - 1] == '*' && @path[pos] != '..')
        case node
        when Hash  then node.each { |k, _| each(node, k, pos, &blk) }
        when Array then node.each_with_index { |_, i| each(node, i, pos, &blk) }
        end
      end
    end

    private

    def filter_context(context, keys)
      case context
      when Hash
        dig_as_hash(context, keys)
      when Array
        context.each_with_object([]) do |c, memo|
          memo << dig_as_hash(c, keys)
        end
      end
    end

    def handle_wildcard(node, expr, _context, _key, pos, &blk)
      expr[1, expr.size - 2].split(',').each do |sub_path|
        case sub_path[0]
        when '\'', '"'
          k = sub_path[1, sub_path.size - 2]
          yield_if_diggable(node, k) do
            each(node, k, pos + 1, &blk)
          end
        when '?'
          handle_question_mark(sub_path, node, pos, &blk)
        else
          next if node.is_a?(Array) && node.empty?
          next if node.nil? # when default_path_leaf_to_null is true
          next if node.size.zero?

          array_args = sub_path.split(':')
          if array_args[0] == '*'
            start_idx = 0
            end_idx = node.size - 1
          elsif sub_path.count(':') == 0
            start_idx = end_idx = process_function_or_literal(array_args[0], 0)
            next unless start_idx
            next if start_idx >= node.size
          else
            start_idx = process_function_or_literal(array_args[0], 0)
            next unless start_idx

            end_idx = array_args[1] && ensure_exclusive_end_index(process_function_or_literal(array_args[1], -1)) || -1
            next unless end_idx
            next if start_idx == end_idx && start_idx >= node.size
          end

          start_idx %= node.size
          end_idx %= node.size
          step = process_function_or_literal(array_args[2], 1)
          next unless step

          if @mode == :delete
            (start_idx..end_idx).step(step) { |i| node[i] = nil }
            node.compact!
          else
            (start_idx..end_idx).step(step) { |i| each(node, i, pos + 1, &blk) }
          end
        end
      end
    end

    def ensure_exclusive_end_index(value)
      return value unless value.is_a?(Integer) && value > 0

      value - 1
    end

    def handle_question_mark(sub_path, node, pos, &blk)
      case node
      when Array
        node.size.times do |index|
          @_current_node = node[index]
          if process_function_or_literal(sub_path[1, sub_path.size - 1])
            each(@_current_node, nil, pos + 1, &blk)
          end
        end
      when Hash
        if process_function_or_literal(sub_path[1, sub_path.size - 1])
          each(@_current_node, nil, pos + 1, &blk)
        end
      else
        yield node if process_function_or_literal(sub_path[1, sub_path.size - 1])
      end
    end

    def yield_value(blk, context, key)
      case @mode
      when nil
        blk.call(key ? dig_one(context, key) : context)
      when :compact
        if key && context[key].nil?
          key.is_a?(Integer) ? context.delete_at(key) : context.delete(key)
        end
      when :delete
        if key
          key.is_a?(Integer) ? context.delete_at(key) : context.delete(key)
        else
          context.replace({})
        end
      when :substitute
        if key
          context[key] = blk.call(context[key])
        else
          context.replace(blk.call(context[key]))
        end
      end
    end

    def process_function_or_literal(exp, default = nil)
      return default if exp.nil? || exp.empty?
      return Integer(exp) if exp[0] != '('
      return nil unless @_current_node

      identifiers = /@?(((?<!\d)\.(?!\d)(\w+))|\['(.*?)'\])+/.match(exp)
      # to filter arrays with known/unknown name.
      if (!identifiers.nil? && !(@_current_node.methods.include?(identifiers[2]&.to_sym) || @_current_node.methods.include?(identifiers[4]&.to_sym)))
        exp_to_eval = exp.dup
        begin
          return JsonPath::Parser.new(@_current_node, @options).parse(exp_to_eval)
        rescue StandardError
          return default
        end
      end
      JsonPath::Parser.new(@_current_node, @options).parse(exp)
    end
  end
end
