require 'cgi'
require 'pact/shared/active_support_support'
require 'pact/symbolize_keys'

module Pact
  class QueryHash

    include ActiveSupportSupport
    include SymbolizeKeys

    attr_reader :original_string

    def initialize(query, original_string = nil, nested = false)
      @hash = query.nil? ? query : convert_to_hash_of_arrays(query)
      @original_string = original_string
      @nested = nested
    end

    def nested?
      @nested
    end

    def any_key_contains_square_brackets?
      query.keys.any?{ |key| key =~ /\[.*\]/ }
    end

    def as_json(opts = {})
      @hash
    end

    def to_json(opts = {})
      as_json(opts).to_json(opts)
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      QueryHash === other && other.query == query
    end

    # other will always be a QueryString, not a QueryHash, as it will have ben created
    # from the actual query string.
    def difference(other)
      require 'pact/matchers' # avoid recursive loop between this file, pact/reification and pact/matchers

      if any_key_contains_square_brackets?
        other_query_hash_non_nested = Query.parse_string_as_non_nested_query(other.query)
        Pact::Matchers.diff(query, convert_to_hash_of_arrays(other_query_hash_non_nested), allow_unexpected_keys: false)
      else
        other_query_hash = Query.parse_string(other.query)
        Pact::Matchers.diff(query, symbolize_keys(convert_to_hash_of_arrays(other_query_hash)), allow_unexpected_keys: false)
      end
    end

    def query
      @hash
    end

    def to_s
      @hash.inspect
    end

    def empty?
      @hash && @hash.empty?
    end

    def to_hash
      @hash
    end

    private

    def convert_to_hash_of_arrays(query)
      query.each_with_object({}) {|(k, v), hash| insert(hash, k, v) }
    end

    def insert(hash, k, v)
      if Hash === v
        v.each {|k2, v2| insert(hash, :"#{k}[#{k2}]", v2) }
      elsif Pact::ArrayLike === v
        hash[k.to_sym] = v
      else
        hash[k.to_sym] = [*v]
      end
    end
  end
end
