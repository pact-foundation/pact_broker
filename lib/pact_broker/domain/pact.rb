require "pact_broker/db"
require "pact_broker/json"
require "pact_broker/pacts/content"

=begin
This class most accurately represents a PactPublication
=end

module PactBroker
  class UnsetAttributeError < StandardError; end
  class UnsetAttribute; end

  module Domain
    class Pact

      # The ID is the pact_publication ID
      attr_accessor :id,
        :provider,
        :consumer_version,
        :created_at,
        :json_content,
        :consumer_version_number,
        :revision_number,
        :pact_version_sha,
        :head_tag_names
      attr_writer :consumer, :latest_verification

      def initialize attributes = {}
        @latest_verification = UnsetAttribute.new
        attributes.each_pair do | key, value |
          self.send(key.to_s + "=", value)
        end
      end

      def consumer_name
        consumer.name
      end

      def provider_name
        provider.name
      end

      def consumer
        @consumer || consumer_version.pacticipant
      end

      def consumer_version_tag_names
        consumer_version.tags.collect(&:name)
      end

      def latest_consumer_version_tag_names= latest_consumer_version_tag_names
        @latest_consumer_version_tag_names = latest_consumer_version_tag_names
      end

      def latest_verification
        get_attribute_if_set :latest_verification
      end

      def to_s
        "Pact: consumer=#{consumer.name} provider=#{provider.name}"
      end

      def to_json _options = {}
        json_content
      end

      def name
        "Pact between #{consumer.name} (#{consumer_version_number}) and #{provider.name}"
      end

      def version_and_updated_date
        "Version #{consumer_version_number} - #{created_at.to_time.localtime.strftime("%d/%m/%Y")}"
      end

      def content_hash
        JSON.parse(json_content, PACT_PARSING_OPTIONS)
      end

      def content_object
        @content_object ||= begin
          PactBroker::Pacts::Content.from_json(json_content)
        rescue
          PactBroker::Pacts::Content.new
        end
      end

      def pact_publication_id
        id
      end

      def select_pending_provider_version_tags(provider_version_tags)
        tags_with_successful_verifications_from_that_branch = db_model.pact_version.select_provider_tags_with_successful_verifications(provider_version_tags)
        tags_with_previous_successful_verifications_from_other_branches = db_model.pact_version.select_provider_tags_with_successful_verifications_from_another_branch_from_before_this_branch_created(provider_version_tags)
        provider_version_tags - tags_with_successful_verifications_from_that_branch - tags_with_previous_successful_verifications_from_other_branches
      end

      # @param [String] branch_name the name of the provider branch that will be verifying the pacts
      # @return Boolean whether or not the pact is in pending state (ie. the build should not fail if the verification fails)
      def pending_for_provider_branch?(branch_name)
        pact_version.pending_for_provider_branch?(branch_name)
      end

      def pending_for_any_provider_branch?
        !pact_version.verified_successfully_by_any_provider_version?
      end

      def <=> other
        self_fields = [consumer_name.downcase, provider_name.downcase, consumer_version.order || 0]
        other_fields = [other.consumer_name.downcase, other.provider_name.downcase, other.consumer_version.order || 0]
        self_fields <=> other_fields
      end

      private

      attr_accessor :db_model

      # Really not sure about mixing Sequel model class into this PORO...
      # But it's much nicer than using a repository to find out the pending information :(
      def pact_version
        db_model.pact_version
      end

      # This class has various incarnations with different properties loaded.
      # They should probably be different classes, but for now, raise an error if
      # an attribute is called when it hasn't been set in the constuctor, because
      # returning nil when there should be an object causes bugs.
      def get_attribute_if_set attribute_name
        val = instance_variable_get("@#{attribute_name}".to_sym)
        if val.is_a?(UnsetAttribute)
          raise UnsetAttributeError.new("Attribute #{attribute_name} not set")
        else
          val
        end
      end
    end
  end
end
