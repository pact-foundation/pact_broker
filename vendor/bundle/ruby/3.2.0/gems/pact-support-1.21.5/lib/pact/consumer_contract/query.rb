require 'pact/consumer_contract/query_hash'
require 'pact/consumer_contract/query_string'

module Pact
  class Query
    DEFAULT_SEP = /[&;] */n
    COMMON_SEP = { ";" => /[;] */n, ";," => /[;,] */n, "&" => /[&] */n }

    class NestedQuery < Hash; end

    def self.create query
      if query.is_a? Hash
        Pact::QueryHash.new(query)
      else
        Pact::QueryString.new(query)
      end
    end

    def self.is_a_query_object?(object)
      object.is_a?(Pact::QueryHash) || object.is_a?(Pact::QueryString)
    end

    def self.parsed_as_nested?(object)
      object.is_a?(NestedQuery)
    end

    def self.parse_string query_string
      parsed_query = parse_string_as_non_nested_query(query_string)

      # If Rails nested params...
      if parsed_query.keys.any?{ | key| key =~ /\[.*\]/ }
        parse_string_as_nested_query(query_string)
      else
        parsed_query.each_with_object({}) do | (key, value), new_hash |
          new_hash[key] = [*value]
        end
      end
    end

    # Ripped from Rack to avoid adding an unnecessary dependency, thank you Rack
    # https://github.com/rack/rack/blob/649c72bab9e7b50d657b5b432d0c205c95c2be07/lib/rack/utils.rb
    def self.parse_string_as_non_nested_query(qs, d = nil, &unescaper)
      unescaper ||= method(:unescape)

      params = {}

      (qs || '').split(d ? (COMMON_SEP[d] || /[#{d}] */n) : DEFAULT_SEP).each do |p|
        next if p.empty?
        k, v = p.split('=', 2).map!(&unescaper)

        if cur = params[k]
          if cur.class == Array
            params[k] << v
          else
            params[k] = [cur, v]
          end
        else
          params[k] = v
        end
      end

      return params.to_h
    end

    def self.parse_string_as_nested_query(qs, d = nil)
      params = {}

      unless qs.nil? || qs.empty?
        (qs || '').split(d ? (COMMON_SEP[d] || /[#{d}] */n) : DEFAULT_SEP).each do |p|
          k, v = p.split('=', 2).map! { |s| unescape(s) }

          normalize_params(params, k, v)
        end
      end

      return NestedQuery[params.to_h]
    end

    def self.normalize_params(params, name, v)
      name =~ %r(\A[\[\]]*([^\[\]]+)\]*)
      k = $1 || ''
      after = $' || ''

      if k.empty?
        if !v.nil? && name == "[]"
          return Array(v)
        else
          return
        end
      end

      if after == ''
        params[k] = v
      elsif after == "["
        params[name] = v
      elsif after == "[]"
        params[k] ||= []
        raise ParameterTypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
        params[k] << v
      elsif after =~ %r(^\[\]\[([^\[\]]+)\]$) || after =~ %r(^\[\](.+)$)
        child_key = $1
        params[k] ||= []
        raise ParameterTypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
        if params_hash_type?(params[k].last) && !params_hash_has_key?(params[k].last, child_key)
          normalize_params(params[k].last, child_key, v)
        else
          params[k] << normalize_params({}, child_key, v)
        end
      else
        params[k] ||= {}
        raise ParameterTypeError, "expected Hash (got #{params[k].class.name}) for param `#{k}'" unless params_hash_type?(params[k])
        params[k] = normalize_params(params[k], after, v)
      end

      params
    end

    def self.params_hash_type?(obj)
      obj.is_a?(Hash)
    end

    def self.params_hash_has_key?(hash, key)
      return false if key =~ /\[\]/

      key.split(/[\[\]]+/).inject(hash) do |h, part|
        next h if part == ''
        return false unless params_hash_type?(h) && h.key?(part)
        h[part]
      end

      true
    end

    def self.unescape(s, encoding = Encoding::UTF_8)
      URI.decode_www_form_component(s, encoding)
    end
  end
end
