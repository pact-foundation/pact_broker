require "pact_broker/api/pact_broker_urls"
require "pact_broker/date_helper"
require "pact_broker/pacts/create_formatted_diff"
require "pact_broker/pacts/sort_content"
require "pact_broker/pacts/parse"
require "pact_broker/repositories"
require "yaml"

module PactBroker
  module Pacts

    class Diff
      include PactBroker::Repositories

      def process(params, comparison_pact_params = nil, options = {})
        pact = find_pact(params)
        comparison_pact = comparison_pact_params ? find_pact(comparison_pact_params) : pact_repository.find_previous_distinct_pact(pact)

        if comparison_pact
          next_pact = pact_repository.find_next_pact(comparison_pact) || pact
          DiffDecorator.new(pact, comparison_pact, next_pact, params[:base_url], { raw: options[:raw] }).to_text
        else
          no_previous_version_message pact
        end
      end

      private

      def find_pact(params)
        pact_repository.find_pact(params.consumer_name,
                                  params.consumer_version_number,
                                  params.provider_name,
                                  params.pact_version_sha)
      end

      def no_previous_version_message(pact)
        "No previous distinct version was found for #{pact.name}"
      end

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
        def initialize(pact, comparison_pact, next_pact, base_url, options)
          @pact = pact
          @comparison_pact = comparison_pact
          @next_pact = next_pact
          @base_url = base_url
          @options = options
        end

        def to_text
          header + "\n\n" + diff + "\n\n" + links
        end

        private

        attr_reader :pact, :comparison_pact, :next_pact, :base_url, :options

        def change_date_in_words
          DateHelper.local_date_in_words next_pact.created_at
        end

        def now
          Time.now
        end

        def header
          title = "# Diff between versions #{comparison_pact.consumer_version_number} and #{pact.consumer_version_number} of the pact between #{pact.consumer.name} and #{pact.provider.name}"
          description = "The following changes were made #{change_date_ago_in_words} ago (#{change_date_in_words})"

          title +  "\n\n" + description
        end

        def links
          self_url = PactBroker::Api::PactBrokerUrls.pact_url(base_url, pact)
          previous_distinct_url = PactBroker::Api::PactBrokerUrls.pact_url(base_url, comparison_pact)

          links = {
            "pact-version" => {
              "title" => "Pact",
              "name" => pact.name,
              "href" => self_url
            },
            "comparison-pact-version" => {
              "title" => "Pact",
              "name" => comparison_pact.name,
              "href" => previous_distinct_url
            }
          }
          "## Links\n" + YAML.dump(links).gsub(/---/,"")
        end

        def diff
          CreateFormattedDiff.(prepare_content(pact.json_content), prepare_content(comparison_pact.json_content))
        end

        def change_date_ago_in_words
          DateHelper.distance_of_time_in_words next_pact.created_at, now
        end

        def prepare_content json_content
          if options[:raw]
            json_content
          else
            SortContent.call(Parse.call(json_content)).to_json
          end
        end
      end
    end
  end
end
