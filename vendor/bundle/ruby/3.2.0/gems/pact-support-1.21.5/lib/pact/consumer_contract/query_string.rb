require 'pact/shared/active_support_support'

module Pact
  class QueryString

    include ActiveSupportSupport

    def initialize query
      @query = query.nil? ? query : query.dup
    end

    def as_json opts = {}
      @query
    end

    def to_json opts = {}
      as_json(opts).to_json(opts)
    end

    def eql? other
      self == other
    end

    def == other
      QueryString === other && other.query == query
    end

    def difference(other)
      require 'pact/matchers' # avoid recursive loop between this file and pact/matchers
      Pact::Matchers.diff(query, other.query)
    end

    def query
      @query
    end

    def to_s
      @query
    end

    def empty?
      @query && @query.empty?
    end

    # Naughty...
    def nil?
      @query.nil?
    end

  end
end