# frozen_string_literal: true

require 'strscan'

class JsonPath
  # Parser parses and evaluates an expression passed to @_current_node.
  class Parser
    include Dig

    REGEX = /\A\/(.+)\/([imxnesu]*)\z|\A%r{(.+)}([imxnesu]*)\z/

    def initialize(node, options)
      @_current_node = node
      @_expr_map = {}
      @options = options
    end

    # parse will parse an expression in the following way.
    # Split the expression up into an array of legs for && and || operators.
    # Parse this array into a map for which the keys are the parsed legs
    #  of the split. This map is then used to replace the expression with their
    # corresponding boolean or numeric value. This might look something like this:
    # ((false || false) && (false || true))
    #  Once this string is assembled... we proceed to evaluate from left to right.
    #  The above string is broken down like this:
    # (false && (false || true))
    # (false && true)
    #  false
    def parse(exp)
      exps = exp.split(/(&&)|(\|\|)/)
      construct_expression_map(exps)
      @_expr_map.each { |k, v| exp.sub!(k, v.to_s) }
      raise ArgumentError, "unmatched parenthesis in expression: #{exp}" unless check_parenthesis_count(exp)

      exp = parse_parentheses(exp) while exp.include?('(')
      bool_or_exp(exp)
    end

    # Construct a map for which the keys are the expressions
    #  and the values are the corresponding parsed results.
    # Exp.:
    # {"(@['author'] =~ /herman|lukyanenko/i)"=>0}
    # {"@['isTrue']"=>true}
    def construct_expression_map(exps)
      exps.each_with_index do |item, _index|
        next if item == '&&' || item == '||'

        item = item.strip.gsub(/\)*$/, '').gsub(/^\(*/, '')
        @_expr_map[item] = parse_exp(item)
      end
    end

    # Using a scanner break down the individual expressions and determine if
    # there is a match in the JSON for it or not.
    def parse_exp(exp)
      exp = exp.sub(/@/, '').gsub(/^\(/, '').gsub(/\)$/, '').tr('"', '\'').strip
      exp.scan(/^\[(\d+)\]/) do |i|
        next if i.empty?

        index = Integer(i[0])
        raise ArgumentError, 'Node does not appear to be an array.' unless @_current_node.is_a?(Array)
        raise ArgumentError, "Index out of bounds for nested array. Index: #{index}" if @_current_node.size < index

        @_current_node = @_current_node[index]
        # Remove the extra '' and the index.
        exp = exp.gsub(/^\[\d+\]|\[''\]/, '')
      end
      scanner = StringScanner.new(exp)
      elements = []
      until scanner.eos?
        if (t = scanner.scan(/\['[a-zA-Z@&*\/$%^?_]+'\]|\.[a-zA-Z0-9_]+[?]?/))
          elements << t.gsub(/[\[\]'.]|\s+/, '')
        elsif (t = scanner.scan(/(\s+)?[<>=!\-+][=~]?(\s+)?/))
          operator = t
        elsif (t = scanner.scan(/(\s+)?'?.*'?(\s+)?/))
          # If we encounter a node which does not contain `'` it means
          #  that we are dealing with a boolean type.
          operand =
            if t == 'true'
              true
            elsif t == 'false'
              false
            elsif operator.to_s.strip == '=~'
              parse_regex(t)
            else
              t.gsub(%r{^'|'$}, '').strip
            end
        elsif (t = scanner.scan(/\/\w+\//))
        elsif (t = scanner.scan(/.*/))
          raise "Could not process symbol: #{t}"
        end
      end

      el = if elements.empty?
             @_current_node
           elsif @_current_node.is_a?(Hash)
             dig(@_current_node, *elements)
           else
             elements.inject(@_current_node, &:__send__)
           end

      return (el ? true : false) if el.nil? || operator.nil?

      el = Float(el) rescue el
      operand = Float(operand) rescue operand

      el.__send__(operator.strip, operand)
    end

    private

    # /foo/i -> Regex.new("foo", Regexp::IGNORECASE) without using eval
    # also supports %r{foo}i
    # following https://github.com/seamusabshere/to_regexp/blob/master/lib/to_regexp.rb
    def parse_regex(t)
      t =~ REGEX
      content = $1 || $3
      options = $2 || $4

      raise ArgumentError, "unsupported regex #{t} use /foo/ style" if !content || !options

      content = content.gsub '\\/', '/'

      flags = 0
      flags |= Regexp::IGNORECASE if options.include?('i')
      flags |= Regexp::MULTILINE if options.include?('m')
      flags |= Regexp::EXTENDED if options.include?('x')

      # 'n' = none, 'e' = EUC, 's' = SJIS, 'u' = UTF-8
      lang = options.scan(/[nes]/).join.downcase # ignores u since that is default and causes a warning

      args = [content, flags]
      args << lang unless lang.empty? # avoid warning
      Regexp.new(*args)
    end

    #  This will break down a parenthesis from the left to the right
    #  and replace the given expression with it's returned value.
    # It does this in order to make it easy to eliminate groups
    # one-by-one.
    def parse_parentheses(str)
      opening_index = 0
      closing_index = 0

      (0..str.length - 1).step(1) do |i|
        opening_index = i if str[i] == '('
        if str[i] == ')'
          closing_index = i
          break
        end
      end

      to_parse = str[opening_index + 1..closing_index - 1]

      #  handle cases like (true && true || false && true) in
      # one giant parenthesis.
      top = to_parse.split(/(&&)|(\|\|)/)
      top = top.map(&:strip)
      res = bool_or_exp(top.shift)
      top.each_with_index do |item, index|
        if item == '&&'
          next_value = bool_or_exp(top[index + 1])
          res &&= next_value
        elsif item == '||'
          next_value = bool_or_exp(top[index + 1])
          res ||= next_value
        end
      end

      #  if we are at the last item, the opening index will be 0
      # and the closing index will be the last index. To avoid
      # off-by-one errors we simply return the result at that point.
      if closing_index + 1 >= str.length && opening_index == 0
        res.to_s
      else
        "#{str[0..opening_index - 1]}#{res}#{str[closing_index + 1..str.length]}"
      end
    end

    #  This is convoluted and I should probably refactor it somehow.
    #  The map that is created will contain strings since essentially I'm
    # constructing a string like `true || true && false`.
    # With eval the need for this would disappear but never the less, here
    #  it is. The fact is that the results can be either boolean, or a number
    # in case there is only indexing happening like give me the 3rd item... or
    # it also can be nil in case of regexes or things that aren't found.
    # Hence, I have to be clever here to see what kind of variable I need to
    # provide back.
    def bool_or_exp(b)
      if b.to_s == 'true'
        return true
      elsif b.to_s == 'false'
        return false
      elsif b.to_s == ''
        return nil
      end

      b = Float(b) rescue b
      b
    end

    # this simply makes sure that we aren't getting into the whole
    #  parenthesis parsing business without knowing that every parenthesis
    # has its pair.
    def check_parenthesis_count(exp)
      return true unless exp.include?('(')

      depth = 0
      exp.chars.each do |c|
        if c == '('
          depth += 1
        elsif c == ')'
          depth -= 1
        end
      end
      depth == 0
    end
  end
end
