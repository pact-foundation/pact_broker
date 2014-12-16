require 'trailblazer/operation'
require 'pact_broker/repositories'
require 'pact_broker/pacts/create_formatted_diff'
require 'pact_broker/api/pact_broker_urls'
require 'yaml'
require 'pact_broker/date_helper'


module PactBroker
  module Pacts

    class Diff < Trailblazer::Operation

      include PactBroker::Repositories
      attr_reader :params, :options

      def process params, options
        pact = pact_repository.find_pact(params.consumer_name, params.consumer_version_number, params.provider_name)
        previous_distinct_pact = pact_repository.find_previous_distinct_pact pact
        next_pact = pact_repository.find_next_pact previous_distinct_pact
        DiffDecorator.new(pact, previous_distinct_pact, next_pact, options[:base_url]).to_text
      end

      private

      # The next pact version after the previous distinct version.
      # Eg. v1 (previous distinct) -> pactContentA
      #     v2 (next pact)         -> pactContentB
      #     v3                     -> pactContentB
      #     v4 (current)           -> pactContentB
      # If we are at v4, then the previous distinct pact version is
      # v1, and the next pact after that is v2.
      # The timestamps on v2 are the ones we want - that's when
      # the latest distinct version content was first created.

      class DiffDecorator

        attr_reader :pact, :previous_distinct_pact, :next_pact, :base_url

        def initialize pact, previous_distinct_pact, next_pact, base_url
          @pact = pact
          @previous_distinct_pact = previous_distinct_pact
          @next_pact = next_pact
          @base_url = base_url
        end

        def to_text
          header + "\n\n" + diff + "\n\n" + links
        end

        private

        def change_date_in_words
          DateHelper.local_date_in_words next_pact.updated_at
        end

        def now
          Time.now
        end

        def header
          title = "# Diff between versions #{previous_distinct_pact.consumer_version_number} and #{pact.consumer_version_number} of the pact between #{pact.consumer.name} and #{pact.provider.name}"
          description = "The following changes were made #{change_date_ago_in_words} ago (#{change_date_in_words})"
          title +  "\n\n" + description
        end

        def links
          self_url = PactBroker::Api::PactBrokerUrls.pact_url base_url, pact
          previous_distinct_url = PactBroker::Api::PactBrokerUrls.pact_url base_url, previous_distinct_pact

          links = {
            "current-pact-version" => {
              "title" => "Pact",
              "name" => pact.name,
              "href" => self_url
            },
            "previous-distinct-pact-version" => {
              "title" => "Pact",
              "name" => previous_distinct_pact.name,
              "href" => previous_distinct_url
            }
          }
          "## Links\n" + YAML.dump(links).gsub(/---/,'')
        end

        def diff
          CreateFormattedDiff.(pact.json_content, previous_distinct_pact.json_content)
        end

        def change_date_ago_in_words
          DateHelper.distance_of_time_in_words next_pact.updated_at, now
        end
      end

    end
  end
end
