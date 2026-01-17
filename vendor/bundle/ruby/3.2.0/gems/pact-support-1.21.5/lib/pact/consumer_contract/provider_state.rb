module Pact
  class ProviderState

    attr_reader :name, :params

    def initialize name, params = {}
      @name = name
      @params = params
    end

    def self.from_hash(hash)
      new(hash["name"], hash["params"])
    end

    def ==(other)
      other.is_a?(Pact::ProviderState) && other.name == self.name && other.params == self.params
    end

    def to_hash
      {
        "name" => name,
        "params" => params
      }
    end

    def to_json(opts = {})
      as_json(opts).to_json(opts)
    end

    def as_json(opts = {})
      to_hash
    end
  end
end
