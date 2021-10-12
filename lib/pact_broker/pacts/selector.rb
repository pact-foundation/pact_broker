require "pact_broker/hash_refinements"

module PactBroker
  module Pacts
    # rubocop: disable Metrics/ClassLength
    class Selector < Hash
      using PactBroker::HashRefinements

      PROPERTY_NAMES = [:latest, :tag, :branch, :consumer, :consumer_version, :environment_name, :fallback_tag, :fallback_branch, :main_branch, :matching_branch, :currently_supported, :currently_deployed]

      def initialize(properties = {})
        properties.without(*PROPERTY_NAMES).tap { |it| warn("WARN: Unsupported property for #{self.class.name}: #{it.keys.join(", ")} at #{caller[0..3]}") if it.any? }
        merge!(properties)
      end

      def resolve(consumer_version)
        ResolvedSelector.new(self.to_h.without(:fallback_tag, :fallback_branch), consumer_version)
      end

      def resolve_for_fallback(consumer_version)
        ResolvedSelector.new(self.to_h, consumer_version)
      end

      def resolve_for_environment(consumer_version, environment, target = nil)
        ResolvedSelector.new(self.to_h.merge({ environment: environment, target: target }.compact), consumer_version)
      end

      # Only currently used to identify the currently_deployed from the others in
      # verifiable_pact_messages, so don't need the "for_consumer" sub category
      # rubocop: disable Metrics/CyclomaticComplexity
      def type
        if latest_for_branch?
          :latest_for_branch
        elsif matching_branch?
          :matching_branch
        elsif currently_deployed?
          :currently_deployed
        elsif currently_supported?
          :currently_supported
        elsif in_environment?
          :in_environment
        elsif latest_for_tag?
          :latest_for_tag
        elsif all_for_tag?
          :all_for_tag
        elsif overall_latest?
          :overall_latest
        else
          :undefined
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def main_branch= main_branch
        self[:main_branch] = main_branch
      end

      def matching_branch= matching_branch
        self[:matching_branch] = matching_branch
      end

      def tag= tag
        self[:tag] = tag
      end

      def branch= branch
        self[:branch] = branch
      end

      def latest= latest
        self[:latest] = latest
      end

      def latest
        self[:latest]
      end

      def fallback_tag= fallback_tag
        self[:fallback_tag] = fallback_tag
      end

      def fallback_branch= fallback_branch
        self[:fallback_branch] = fallback_branch
      end

      def fallback_tag
        self[:fallback_tag]
      end

      def fallback_branch
        self[:fallback_branch]
      end

      def consumer= consumer
        self[:consumer] = consumer
      end

      def consumer
        self[:consumer]
      end

      def currently_deployed= currently_deployed
        self[:currently_deployed] = currently_deployed
      end

      def currently_deployed
        self[:currently_deployed]
      end

      def currently_deployed?
        !!currently_deployed
      end

      def currently_supported= currently_supported
        self[:currently_supported] = currently_supported
      end

      def currently_supported
        self[:currently_supported]
      end

      def currently_supported?
        !!currently_supported
      end

      def environment_name= environment_name
        self[:environment_name] = environment_name
      end

      def environment_name
        self[:environment_name]
      end

      def in_environment?
        !!environment_name
      end

      def self.overall_latest
        Selector.new(latest: true)
      end

      def self.for_main_branch
        Selector.new(main_branch: true)
      end

      def self.latest_for_tag(tag)
        Selector.new(latest: true, tag: tag)
      end

      def self.latest_for_branch(branch)
        Selector.new(latest: true, branch: branch)
      end

      def self.latest_for_tag_with_fallback(tag, fallback_tag)
        Selector.new(latest: true, tag: tag, fallback_tag: fallback_tag)
      end

      def self.latest_for_branch_with_fallback(branch, fallback_branch)
        Selector.new(latest: true, branch: branch, fallback_branch: fallback_branch)
      end

      def self.all_for_tag(tag)
        Selector.new(tag: tag)
      end

      def self.all_for_tag_and_consumer(tag, consumer)
        Selector.new(tag: tag, consumer: consumer)
      end

      def self.latest_for_tag_and_consumer(tag, consumer)
        Selector.new(latest: true, tag: tag, consumer: consumer)
      end

      def self.latest_for_branch_and_consumer(branch, consumer)
        Selector.new(latest: true, branch: branch, consumer: consumer)
      end

      def self.latest_for_consumer(consumer)
        Selector.new(latest: true, consumer: consumer)
      end

      def self.for_currently_deployed(environment_name = nil)
        Selector.new( { currently_deployed: true, environment_name: environment_name }.compact )
      end

      def self.for_currently_supported(environment_name = nil)
        Selector.new( { currently_supported: true, environment_name: environment_name }.compact )
      end

      def self.for_currently_deployed_and_consumer(consumer)
        Selector.new(currently_deployed: true, consumer: consumer)
      end

      def self.for_currently_deployed_and_environment_and_consumer(environment_name, consumer)
        Selector.new(currently_deployed: true, environment_name: environment_name, consumer: consumer)
      end

      def self.for_currently_supported_and_environment_and_consumer(environment_name, consumer)
        Selector.new(currently_supported: true, environment_name: environment_name, consumer: consumer)
      end

      def self.for_environment(environment_name)
        Selector.new(environment_name: environment_name)
      end

      def self.for_environment_and_consumer(environment_name, consumer)
        Selector.new(environment_name: environment_name, consumer: consumer)
      end

      def self.from_hash hash
        Selector.new(hash)
      end

      def for_consumer(consumer)
        Selector.new(to_h.merge(consumer: consumer))
      end

      def latest_for_main_branch?
        !!main_branch
      end

      def fallback_tag?
        !!fallback_tag
      end

      def fallback_branch?
        !!fallback_branch
      end

      def main_branch
        self[:main_branch]
      end

      def tag
        self[:tag]
      end

      def branch
        self[:branch]
      end

      def matching_branch
        self[:matching_branch]
      end

      def matching_branch?
        !!matching_branch
      end

      def overall_latest?
        !!(latest? && !tag && !branch && !main_branch && !currently_deployed && !currently_supported && !environment_name)
      end

      # Not sure if the fallback_tag logic is needed
      def latest_for_tag? potential_tag = nil
        if potential_tag
          !!(latest && tag == potential_tag)
        else
          !!(latest && !!tag)
        end
      end

      # Not sure if the fallback_tag logic is needed
      def latest_for_branch? potential_branch = nil
        if potential_branch
          !!(latest && branch == potential_branch)
        else
          !!(latest && !!branch)
        end
      end

      def all_for_tag_and_consumer?
        !!(tag && !latest? && consumer)
      end

      def all_for_tag?
        !!(tag && !latest?)
      end

      def == other
        other.class == self.class && super
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      def <=> other
        # elsif consumer || other.consumer
        #   consumer_comparison(other)
        if overall_latest? || other.overall_latest?
          overall_latest_comparison(other)
        elsif latest_for_branch? || other.latest_for_branch?
          branch_comparison(other)
        elsif latest_for_tag? || other.latest_for_tag?
          latest_for_tag_comparison(other)
        elsif tag || other.tag
          tag_comparison(other)
        elsif currently_deployed? || other.currently_deployed?
          currently_deployed_comparison(other)
        elsif currently_supported? || other.currently_supported?
          currently_supported_comparison(other)
        else
          0
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      private

      def overall_latest_comparison(other)
        if overall_latest? == other.overall_latest?
          0
        else
          overall_latest? ? -1 : 1
        end
      end

      def branch_comparison(other)
        if latest_for_branch? == other.latest_for_branch?
          branch <=> other.branch
        else
          latest_for_branch? ? -1 : 1
        end
      end

      def currently_deployed_comparison(other)
        if currently_deployed? == other.currently_deployed?
          environment_name <=> other.environment_name
        else
          currently_deployed? ? -1 : 1
        end
      end

      def currently_supported_comparison(other)
        if currently_supported? == other.currently_supported?
          environment_name <=> other.environment_name
        else
          currently_supported? ? -1 : 1
        end
      end

      def latest_for_tag_comparison(other)
        if latest_for_tag? == other.latest_for_tag?
          tag <=> other.tag
        else
          latest_for_tag? ? -1 : 1
        end
      end

      def tag_comparison(other)
        if tag && other.tag
          if tag == other.tag
            consumer_comparison(other)
          else
            tag <=> other.tag
          end
        else
          tag ? -1 : 1
        end
      end

      def consumer_comparison(other)
        if consumer == other.consumer
          0
        else
          consumer ? -1 : 1
        end
      end

      def latest?
        !!self[:latest]
      end
    end

    class ResolvedSelector < Selector
      using PactBroker::HashRefinements

      PROPERTY_NAMES = Selector::PROPERTY_NAMES + [:consumer_version, :environment, :target]

      def initialize(properties = {}, consumer_version)
        properties.without(*PROPERTY_NAMES).tap { |it| warn("WARN: Unsupported property for #{self.class.name}: #{it.keys.join(", ")} at #{caller[0..3]}") if it.any? }
        merge!(properties.merge(consumer_version: consumer_version))
      end

      def consumer_version
        self[:consumer_version]
      end

      def environment
        self[:environment]
      end

      def == other
        super && consumer_version == other.consumer_version
      end

      def <=> other
        comparison = super
        if comparison == 0
          consumer_version.order <=> other.consumer_version.order
        else
          comparison
        end
      end

      def currently_deployed_comparison(other)
        if currently_deployed? == other.currently_deployed?
          production_comparison(other)
        else
          currently_deployed? ? -1 : 1
        end

      end

      def currently_supported_comparison(other)
        if currently_supported? == other.currently_supported?
          production_comparison(other)
        else
          currently_supported? ? -1 : 1
        end
      end

      def production_comparison(other)
        if environment.production? == other.environment.production?
          environment.name <=> other.environment.name
        else
          environment.production? ? 1 : -1
        end
      end
    end
    # rubocop: enable Metrics/ClassLength
  end
end
