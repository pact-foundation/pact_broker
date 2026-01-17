require 'expgen'
require 'pact/term'
require 'pact/something_like'
require 'pact/array_like'
require 'pact/shared/request'
require 'pact/consumer_contract/query_hash'
require 'pact/consumer_contract/query_string'
require 'pact/consumer_contract/string_with_matching_rules'

module Pact
  module Reification
    include ActiveSupportSupport

    def self.from_term(term)
      case term
      when Pact::Term, Pact::SomethingLike, Pact::ArrayLike
        from_term(term.generate)
      when Regexp
        from_term(Expgen.gen(term))
      when Hash
        term.inject({}) do |mem, (key,t)|
          mem[key] = from_term(t)
          mem
        end
      when Array
        term.map{ |t| from_term(t)}
      when Pact::Request::Base
        from_term(term.to_hash)
      when Pact::QueryString
        from_term(term.query)
      when Pact::QueryHash
        if term.original_string
          term.original_string
        else
          from_term(term.query).map { |k, v|
            if v.nil?
              k
            elsif v.is_a?(Array) #For cases where there are multiple instance of the same parameter
              v.map { |x| "#{k}=#{escape(x)}"}.join('&')
            else
              "#{k}=#{escape(v)}"
            end
          }.join('&')
        end
      when Pact::StringWithMatchingRules
        String.new(term)
      else
        term
      end
    end

    def self.escape(str)
      URI.encode_www_form_component(str)
    end
  end
end
