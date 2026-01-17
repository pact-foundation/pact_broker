require 'pact/array_like'
require 'pact/matching_rules/jsonpath'

module Pact
  module MatchingRules
    class Merge

      def self.call expected, matching_rules, root_path = '$'
        new(expected, matching_rules, root_path).call
      end

      def initialize expected, matching_rules, root_path
        @expected = expected
        @matching_rules = standardise_paths(matching_rules)
        @root_path = JsonPath.new(root_path).to_s
        @used_rules = []
      end

      def call
        return @expected if @matching_rules.nil? || @matching_rules.empty?
        recurse(@expected, @root_path).tap { log_ignored_rules }
      end

      private

      def standardise_paths matching_rules
        return matching_rules if matching_rules.nil? || matching_rules.empty?
        matching_rules.each_with_object({}) do | (path, rule), new_matching_rules |
          new_matching_rules[JsonPath.new(path).to_s] = rule
        end
      end

      def recurse expected, path
        recursed = case expected
        when Hash then recurse_hash(expected, path)
        when Array then recurse_array(expected, path)
        else
          expected
        end

        wrap(recursed, path)
      end

      def recurse_hash hash, path
        hash.each_with_object({}) do | (k, v), new_hash |
          new_path = path + "['#{k}']"
          new_hash[k] = recurse(v, new_path)
        end
      end

      def recurse_array array, path
        parent_match_rule = find_rule(path, 'match')
        log_used_rule(path, 'match', parent_match_rule) if parent_match_rule

        array_like_children_path = "#{path}[*]*"
        children_match_rule = find_rule(array_like_children_path, 'match')
        log_used_rule(array_like_children_path, 'match', children_match_rule) if children_match_rule

        min = find_rule(path, 'min')
        log_used_rule(path, 'min', min) if min

        if min && (children_match_rule == 'type' || (children_match_rule.nil? && parent_match_rule == 'type'))
          warn_when_not_one_example_item(array, path)
          Pact::ArrayLike.new(recurse(array.first, "#{path}[*]"), min: min)
        else
          new_array = []
          array.each_with_index do | item, index |
            new_path = path + "[#{index}]"
            new_array << recurse(item, new_path)
          end
          new_array
        end
      end

      def warn_when_not_one_example_item array, path
        unless array.size == 1
          Pact.configuration.error_stream.puts "WARN: Only the first item will be used to match the items in the array at #{path}"
        end
      end

      def wrap object, path
        if find_rule(path, 'match') == 'type' && !find_rule(path, 'min')
          handle_match_type(object, path)
        elsif find_rule(path, 'regex')
          handle_regex(object, path)
        else
          object
        end
      end

      def handle_match_type object, path
        log_used_rule(path, 'match', 'type')
        Pact::SomethingLike.new(object)
      end

      def handle_regex object, path
        regex = find_rule(path, 'regex')
        log_used_rule(path, 'match', 'regex') # assumed to be present
        log_used_rule(path, 'regex', regex)
        Pact::Term.new(generate: object, matcher: Regexp.new(regex))
      end

      def log_ignored_rules
        dup_rules = @matching_rules.dup
        @used_rules.each do | (path, key, value) |
          dup_rules[path].delete(key) if dup_rules[path][key] == value
        end

        if dup_rules.any?
          dup_rules.each do | path, rules |
            $stderr.puts "WARN: Ignoring unsupported matching rules #{rules} for path #{path}" if rules.any?
          end
        end
      end

      def find_rule(path, key)
        @matching_rules[path] && @matching_rules[path][key]
      end

      def log_used_rule path, key, value
        @used_rules << [path, key, value]
      end
    end
  end
end
