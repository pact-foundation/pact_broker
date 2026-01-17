require 'pact/something_like'
require 'pact/array_like'
require 'pact/term'

module Pact
  module MatchingRules::V3
    class Extract

      def self.call matchable
        new(matchable).call
      end

      def initialize matchable
        @matchable = matchable
        @rules = Hash.new
      end

      def call
        recurse matchable, "$", nil
        rules
      end

      private

      attr_reader :matchable, :rules

      def recurse object, path, match_type
        case object
        when Hash then recurse_hash(object, path, match_type)
        when Array then recurse_array(object, path, match_type)
        when Pact::SomethingLike then handle_something_like(object, path, match_type)
        when Pact::ArrayLike then handle_array_like(object, path, match_type)
        when Pact::Term then record_regex_rule object, path
        when Pact::QueryString then recurse(object.query, path, match_type)
        when Pact::QueryHash then recurse_hash(object.query, path, match_type)
        end
      end

      def recurse_hash hash, path, match_type
        hash.each do | (key, value) |
          recurse value, "#{path}#{next_path_part(key)}", match_type
        end
      end

      def recurse_array new_array, path, match_type
        new_array.each_with_index do | value, index |
          recurse value, "#{path}[#{index}]", match_type
        end
      end

      def handle_something_like something_like, path, match_type
        record_match_type_rule path, "type"
        recurse something_like.contents, path, "type"
      end

      def handle_array_like array_like, path, match_type
        record_rule "#{path}", 'min' => array_like.min
        record_match_type_rule "#{path}[*].*", 'type'
        recurse array_like.contents, "#{path}[*]", :array_like
      end

      def record_rule path, rule
        rules[path] ||= {}
        rules[path]['matchers'] ||= []
        rules[path]['matchers'] << rule
      end

      def record_regex_rule term, path
        rules[path] ||= {}
        rules[path]['matchers'] ||= []
        rule = { 'match' => 'regex', 'regex' => term.matcher.inspect[1..-2]}
        rules[path]['matchers'] << rule
      end

      def record_match_type_rule path, match_type
        unless match_type == :array_like || match_type.nil?
          rules[path] ||= {}
          rules[path]['matchers'] ||= []
          rules[path]['matchers'] << { 'match' => match_type }
        end
      end

      # Beth: there's a potential bug if the key contains a dot and a single quote.
      # Not sure what to do then.
      def next_path_part key
        if key.to_s.include?('.')
          "['#{key}']"
        else
          ".#{key}"
        end
      end
    end
  end
end
