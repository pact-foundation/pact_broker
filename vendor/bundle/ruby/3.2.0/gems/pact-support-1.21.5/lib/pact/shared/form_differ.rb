require 'uri'

module Pact
  class FormDiffer

    def self.call expected, actual, options = {}
      require 'pact/matchers' # avoid recursive loop between this file and pact/matchers
      ::Pact::Matchers.diff to_hash(expected), to_hash(actual), options
    end

    def self.to_hash form_body
      if form_body.is_a?(Hash)
        ensure_values_are_arrays form_body
      else
        decode_www_form form_body
      end
    end

    def self.ensure_values_are_arrays hash
      hash.each_with_object({}) do | (key, value), h |
        h[key.to_s] = [*value]
      end
    end

    def self.decode_www_form string
      URI.decode_www_form(string).each_with_object({}) do | (key, value), hash |
        hash[key] ||= []
        hash[key] << value
      end
    end
  end
end
