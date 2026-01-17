# frozen_string_literal: true

module OpenapiParameters
  # This is a wrapper around the Rack env hash that allows us to access headers with headers names
  class HeadersHash
    # This was copied from this Rack::Request PR: https://github.com/rack/rack/pull/1881
    # It is not yet released in Rack, so we copied it here.
    def initialize(env)
      @env = env
    end

    def [](k)
      @env[header_to_env_key(k)]
    end

    def key?(k)
      @env.key?(header_to_env_key(k))
    end

    def header_to_env_key(k)
      k = k.upcase
      k.tr!('-', '_')
      k = "HTTP_#{k}" unless %w[CONTENT_LENGTH CONTENT_TYPE].include?(k)
      k
    end
  end
end
