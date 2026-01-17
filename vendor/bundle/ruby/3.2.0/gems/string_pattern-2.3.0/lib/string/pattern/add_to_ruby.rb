class Array
  # It will generate an string following the pattern specified
  # The positions with string patterns need to be supplied like symbols:
  # [:"10:N", "fixed", :"10-20:XN/x/"].generate #> "1024320001fixed4OZjNMTnuBibwwj"
  def generate(expected_errors: [], **synonyms)
    StringPattern.generate(self, expected_errors: expected_errors, **synonyms)
  end

  alias gen generate

  # it will validate an string following the pattern specified
  def validate(string_to_validate, expected_errors: [], not_expected_errors: [], **synonyms)
    StringPattern.validate(text: string_to_validate, pattern: self, expected_errors: expected_errors, not_expected_errors: not_expected_errors, **synonyms)
  end

  alias val validate
end

class String
  # it will generate an string following the pattern specified
  def generate(expected_errors: [], **synonyms)
    StringPattern.generate(self, expected_errors: expected_errors, **synonyms)
  end

  alias gen generate

  # it will validate an string following the pattern specified
  def validate(string_to_validate, expected_errors: [], not_expected_errors: [], **synonyms)
    StringPattern.validate(text: string_to_validate, pattern: self, expected_errors: expected_errors, not_expected_errors: not_expected_errors, **synonyms)
  end

  alias val validate

  ########################################################
  # Convert to CamelCase a string
  ########################################################
  def to_camel_case
    return self if self !~ /_/ && self !~ /\s/ && self =~ /^[A-Z]+.*/

    gsub(/[^a-zA-Z0-9ññÑáéíóúÁÉÍÓÚüÜ_]/, "_")
      .split("_").map(&:capitalize).join
  end

  ########################################################
  # Convert to snake_case a string
  ########################################################
  def to_snake_case
    gsub(/\W/, '_')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z])([A-Z])/, '\1_\2')
      .downcase
      .gsub(/_+/, '_')
  end
end

class Symbol
  # it will generate an string following the pattern specified
  def generate(expected_errors: [], **synonyms)
    StringPattern.generate(self, expected_errors: expected_errors, **synonyms)
  end

  alias gen generate

  # it will validate an string following the pattern specified
  def validate(string_to_validate, expected_errors: [], not_expected_errors: [], **synonyms)
    StringPattern.validate(text: string_to_validate, pattern: to_s, expected_errors: expected_errors, not_expected_errors: not_expected_errors, **synonyms)
  end

  alias val validate
end

class Regexp

  # it will generate an string following the pattern specified
  def generate(expected_errors: [], **synonyms)
    StringPattern.generate(self, expected_errors: expected_errors, **synonyms)
  end

  alias gen generate

  # adds method to convert a Regexp to StringPattern
  # returns an array of string patterns or just one string pattern
  def to_sp
    regexp_s = self.to_s
    return StringPattern.cache[regexp_s] unless StringPattern.cache[regexp_s].nil?
    regexp = Regexp.new regexp_s
    require "regexp_parser"
    default_infinite = StringPattern.default_infinite
    pata = []
    pats = ""
    patg = [] # for (aa|bb|cc) group
    set = false
    set_negate = false
    options = []
    capture = false

    range = ""
    fixed_text = false
    options = regexp.to_s.scan(/\A\(\?([mix]*)\-[mix]*:/).join.split('')
    last_char = (regexp.to_s.gsub(/\A\(\?[mix]*\-[mix]*:/, "").length) - 2
    Regexp::Scanner.scan regexp do |type, token, text, ts, te|
      if type == :escape
        if token == :dot
          token = :literal
          text = "."
        elsif token == :literal and text.size == 2
          text = text[1]
        else
          puts "Report token not controlled: type: #{type}, token: #{token}, text: '#{text}' [#{ts}..#{te}]"
        end
      end

      unless set || (token == :interval) || (token == :zero_or_one) ||
             (token == :zero_or_more) || (token == :one_or_more) || (pats == "")
        if (pats[0] == "[") && (pats[-1] == "]")
          pats[0] = ""
          if (token == :alternation) || !patg.empty?
            if fixed_text
              if patg.size == 0
                patg << (pata.pop + pats.chop)
              else
                patg[-1] += pats.chop
              end
            else
              patg << pats.chop
            end
          else
            if fixed_text
              pata[-1] += pats.chop
            else
              if pats.size == 2
                pata << pats.chop
              else
                pata << "1:[#{pats}"
              end
              if last_char == te and type == :literal and token == :literal
                pata << text
                pats = ""
                next
              end
            end
          end
        else
          if (token == :alternation) || !patg.empty?
            patg << "1:#{pats}"
          else
            pata << "1:#{pats}"
          end
        end
        pats = ""
      end
      fixed_text = false
      case token
      when :open
        set = true
        pats += "["
      when :close
        if type == :set
          set = false
          if pats[-1] == "["
            pats.chop!
          else
            if set_negate
              pats+="%]*"
              set_negate = false
            else
              pats += "]"
            end    

          end
        elsif type == :group
          capture = false
          unless patg.empty?
            patg << pats if pats.to_s != ""
            pata << patg
            patg = []
            pats = ""
          end
        end
      when :negate
        if set and pats[-1] == '['
          pats+="%"
          set_negate = true
        end
      when :capture
        capture = true if type == :group
      when :alternation
        if type == :meta
          if pats != ""
            patg << pats
            pats = ""
          elsif patg.empty?
            # for the case the first element was not added to patg and was on pata fex: (a+|b|c)
            patg << pata.pop
          end
        end
      when :range
        pats.chop! if options.include?('i')
        range = pats[-1]
        pats.chop!
      when :digit
        pats += "n"
      when :nondigit
        pats += "*[%0123456789%]"
      when :space
        pats += "_"
      when :nonspace
        pats += "*[% %]"
      when :word
        pats += "Ln_"
      when :nonword
        pats += "$"
      when :word_boundary
        pats += "$"
      when :dot
        pats += "*"
      when :literal
        if range == ""
          if text.size > 1
            fixed_text = true
            if !patg.empty?
              patg << text.chop
            else
              pata << text.chop
            end
            pats = text[-1]
          else
            pats += text
            pats += text.upcase if options.include?('i')
          end
        else
          range = range + "-" + text
          if range == "a-z"
            if options.include?('i')
              pats = "L" + pats
            else
              pats = "x" + pats
            end
          elsif range == "A-Z"
            if options.include?('i')
              pats = "L" + pats
            else
              pats = "X" + pats
            end
          elsif range == "0-9"
            pats = "n" + pats
          else
            if set
              pats += (range[0]..range[2]).to_a.join
              if options.include?('i')
                pats += (range[0]..range[2]).to_a.join.upcase
              end
            else
              trange = (range[0]..range[2]).to_a.join
              if options.include?('i')
                trange += trange.upcase
              end
              pats += "[" + trange + "]"
            end
          end
          range = ""
        end
        pats = "[" + pats + "]" unless set
      when :interval
        size = text.sub(",", "-").sub("{", "").sub("}", "")
        size+=(default_infinite+size.chop.to_i).to_s if size[-1] == "-"
        pats = size + ":" + pats
        if !patg.empty?
          patg << pats
        else
          pata << pats
        end
        pats = ""
      when :zero_or_one
        pats = "0-1:" + pats
        if !patg.empty?
          patg << pats
        else
          pata << pats
        end
        pats = ""
      when :zero_or_more
        pats = "0-#{default_infinite}:" + pats
        if !patg.empty?
          patg << pats
        else
          pata << pats
        end
        pats = ""
      when :one_or_more
        pats = "1-#{default_infinite}:" + pats
        if !patg.empty?
          patg << pats
        else
          pata << pats
        end
        pats = ""
      end
    end
    if pats != ""
      if pata.empty?
        if pats[0] == "[" and pats[-1] == "]" #fex: /[12ab]/
          pata = ["1:#{pats}"]
        end
      else
        pata[-1] += pats[1] #fex: /allo/
      end
    end
    if pata.size == 1 and pata[0].kind_of?(String)
      res = pata[0]
    else
      res = pata
    end
    StringPattern.cache[regexp_s] = res
    return res
  end
end

module Kernel
  public

  # if string or symbol supplied it will generate a string with the supplied pattern specified on the string
  # if array supplied then it will generate a string with the supplied patterns. If a position contains a pattern supply it as symbol, for example: [:"10:N", "fixed", :"10-20:XN/x/"]
  def generate(pattern, expected_errors: [], **synonyms)
    if pattern.is_a?(String) || pattern.is_a?(Array) || pattern.is_a?(Symbol) || pattern.is_a?(Regexp)
      StringPattern.generate(pattern, expected_errors: expected_errors, **synonyms)
    else
      puts " Kernel generate method: class not recognized:#{pattern.class}"
    end
  end

  alias gen generate
end
