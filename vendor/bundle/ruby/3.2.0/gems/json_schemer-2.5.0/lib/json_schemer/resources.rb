# frozen_string_literal: true
module JSONSchemer
  class Resources
    def initialize
      @resources = {}
    end

    def [](uri)
      @resources[uri.to_s]
    end

    def []=(uri, resource)
      @resources[uri.to_s] = resource
    end

    def fetch(uri)
      @resources.fetch(uri.to_s)
    end

    def key?(uri)
      @resources.key?(uri.to_s)
    end
  end
end
