require "pact_broker/pacts/selector"

module PactBroker
  module Pacts
    class Selectors < Array
      def initialize *selectors
        super([*selectors].flatten)
      end

      def self.create_for_all_of_each_tag(tag_names)
        Selectors.new(tag_names.collect{ | tag_name | Selector.all_for_tag(tag_name) })
      end

      def self.create_for_latest_of_each_tag(tag_names)
        Selectors.new(tag_names.collect{ | tag_name | Selector.latest_for_tag(tag_name) })
      end

      def self.create_for_latest_for_tag(tag_name)
        Selectors.new([Selector.latest_for_tag(tag_name)])
      end

      def self.create_for_latest_of_each_branch(branches)
        Selectors.new(branches.collect{ | branch | Selector.latest_for_branch(branch) })
      end

      def self.create_for_latest_for_branch(branch)
        Selectors.new([Selector.latest_for_branch(branch)])
      end

      def self.create_for_overall_latest
        Selectors.new([Selector.overall_latest])
      end

      def resolve(consumer_version)
        Selectors.new(collect{ |selector| selector.resolve(consumer_version) })
      end

      def resolve_for_environment(consumer_version, environment)
        Selectors.new(collect{ |selector| selector.resolve_for_environment(consumer_version, environment) })
      end

      def + other
        Selectors.new(super)
      end

      def overall_latest?
        any?(&:overall_latest?)
      end

      def latest_for_tag? potential_tag = nil
        any? { | selector | selector.latest_for_tag?(potential_tag) }
      end

      def tag_names_of_selectors_for_all_pacts
        select(&:all_for_tag?).collect(&:tag).uniq
      end

      def tag_names_of_selectors_for_latest_pacts
        select(&:latest_for_tag?).collect(&:tag).uniq
      end

      def branches_of_selectors_for_latest_pacts
        select(&:latest_for_branch?).collect(&:branch).uniq
      end
    end
  end
end
