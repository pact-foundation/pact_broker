class StringPattern
  ###############################################
  # Analyze the pattern supplied and returns an object of Pattern structure including:
  # min_length, max_length, symbol_type, required_data, excluded_data, data_provided, string_set, all_characters_set
  ###############################################
  def StringPattern.analyze(pattern, silent: false)
    #unless @cache[pattern.to_s].nil?
    #  return Pattern.new(@cache[pattern.to_s].min_length.clone, @cache[pattern.to_s].max_length.clone,
    #                     @cache[pattern.to_s].symbol_type.clone, @cache[pattern.to_s].required_data.clone,
    #                     @cache[pattern.to_s].excluded_data.clone, @cache[pattern.to_s].data_provided.clone,
    #                     @cache[pattern.to_s].string_set.clone, @cache[pattern.to_s].all_characters_set.clone, @cache[pattern.to_s].unique.clone)
    #end
    return @cache[pattern.to_s].clone unless @cache[pattern.to_s].nil?
    min_length, max_length, symbol_type = pattern.to_s.scan(/(\d+)-(\d+):(.+)/)[0]
    if min_length.nil?
      min_length, symbol_type = pattern.to_s.scan(/^!?(\d+):(.+)/)[0]
      max_length = min_length
      if min_length.nil?
        puts "pattern argument not valid on StringPattern.generate: #{pattern.inspect}" unless silent
        return pattern.to_s
      end
    end
    if symbol_type[-1] == "&"
      symbol_type.chop!
      unique = true
    else
      unique = false
    end

    symbol_type = "!" + symbol_type if pattern.to_s[0] == "!"
    min_length = min_length.to_i
    max_length = max_length.to_i

    required_data = Array.new
    excluded_data = Array.new
    required = false
    excluded = false
    data_provided = Array.new
    a = symbol_type
    begin_provided = a.index("[")
    excluded_end_tag = false
    unless begin_provided.nil?
      c = begin_provided + 1
      until c == a.size or (a[c..c] == "]" and a[c..c + 1] != "]]")
        if a[c..c + 1] == "]]"
          data_provided.push("]")
          c = c + 2
        elsif a[c..c + 1] == "%%" and !excluded
          data_provided.push("%")
          c = c + 2
        else
          if a[c..c] == "/" and !excluded
            if a[c..c + 1] == "//"
              data_provided.push(a[c..c])
              if required
                required_data.push([a[c..c]])
              end
              c = c + 1
            else
              if !required
                required = true
              else
                required = false
              end
            end
          else
            if required
              required_data.push([a[c..c]])
            else
              if a[c..c] == "%"
                if a[c..c + 1] == "%%" and excluded
                  excluded_data.push([a[c..c]])
                  c = c + 1
                else
                  if !excluded
                    excluded = true
                  else
                    excluded = false
                    excluded_end_tag = true
                  end
                end
              else
                if excluded
                  excluded_data.push([a[c..c]])
                end
              end
            end
            if excluded == false and excluded_end_tag == false
              data_provided.push(a[c..c])
            end
            excluded_end_tag = false
          end
          c = c + 1
        end
      end
      symbol_type = symbol_type[0..begin_provided].to_s + symbol_type[c..symbol_type.size].to_s
    end

    required = false
    required_symbol = ""
    if symbol_type.include?("/")
      symbol_type.chars.each { |stc|
        if stc == "/"
          if !required
            required = true
          else
            required = false
          end
        else
          if required
            required_symbol += stc
          end
        end
      }
    end

    national_set = @national_chars.chars

    if symbol_type.include?("L")
      alpha_set = ALPHA_SET_LOWER.clone + ALPHA_SET_CAPITAL.clone
    elsif symbol_type.include?("x")
      alpha_set = ALPHA_SET_LOWER.clone
      if symbol_type.include?("X")
        alpha_set = alpha_set + ALPHA_SET_CAPITAL.clone
      end
    elsif symbol_type.include?("X")
      alpha_set = ALPHA_SET_CAPITAL.clone
    else
      alpha_set = []
    end
    if symbol_type.include?("T")
      alpha_set = alpha_set + national_set
    end

    unless required_symbol.nil?
      if required_symbol.include?("x")
        required_data.push ALPHA_SET_LOWER.clone
      end
      if required_symbol.include?("X")
        required_data.push ALPHA_SET_CAPITAL.clone
      end
      if required_symbol.include?("L")
        required_data.push(ALPHA_SET_CAPITAL.clone + ALPHA_SET_LOWER.clone)
      end
      if required_symbol.include?("T")
        required_data.push national_set
      end
      required_symbol = required_symbol.downcase
    end
    string_set = Array.new

    all_characters_set = ALPHA_SET_CAPITAL.clone + ALPHA_SET_LOWER.clone + NUMBER_SET.clone + SPECIAL_SET.clone + data_provided + national_set
    if symbol_type.include?("_")
      unless symbol_type.include?("$")
        string_set.push(" ")
      end
      if required_symbol.include?("_")
        required_data.push([" "])
      end
    end

    #symbol_type = symbol_type.downcase

    if symbol_type.downcase.include?("x") or symbol_type.downcase.include?("l") or symbol_type.downcase.include?("t")
      string_set = string_set + alpha_set
    end
    if symbol_type.downcase.include?("n")
      string_set = string_set + NUMBER_SET
    end
    if symbol_type.include?("$")
      string_set = string_set + SPECIAL_SET
    end
    if symbol_type.include?("*")
      string_set = string_set + all_characters_set
    end
    if data_provided.size != 0
      string_set = string_set + data_provided
    end
    unless required_symbol.empty?
      if required_symbol.include?("n")
        required_data.push NUMBER_SET.clone
      end
      if required_symbol.include?("$")
        required_data.push SPECIAL_SET.clone
      end
    end
    unless excluded_data.empty?
      string_set = string_set - excluded_data.flatten
    end
    string_set.uniq!
    @cache[pattern.to_s] = Pattern.new(min_length, max_length, symbol_type, required_data, excluded_data, data_provided,
                                       string_set, all_characters_set, unique)
    return @cache[pattern.to_s].clone
  end
end
