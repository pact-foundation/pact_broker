require "ostruct"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/api/decorators/format_date_time"

module PactBroker
  module Api
    module Decorators
      class DashboardDecorator
        include PactBroker::Api::PactBrokerUrls
        include FormatDateTime

        def initialize(index_items)
          @index_items = index_items
        end

        def to_json(options)
          to_hash(options).to_json
        end

        def to_hash(options)
          {
            items: items(index_items, options[:user_options][:base_url])
          }
        end

        private

        attr_reader :index_items

        def items(_index_items, base_url)
          sorted_index_items.collect do | index_item |
            index_item_hash(index_item.consumer, index_item.provider, index_item.consumer_version, index_item, base_url)
          end
        end

        def sorted_index_items
          index_items.sort{ |i1, i2| i2.last_activity_date <=> i1.last_activity_date }
        end

        def index_item_hash(consumer, provider, consumer_version, index_item, base_url)
          {
            consumer: consumer_hash(index_item, consumer, consumer_version, base_url),
            provider: provider_hash(index_item, provider, base_url),
            pact: pact_hash(index_item, base_url),
            pactTags: pact_tags(index_item, base_url),
            latestVerificationResult: verification_hash(index_item, base_url),
            latestVerificationResultTags: verification_tags(index_item, base_url),
            verificationStatus: index_item.pseudo_branch_verification_status.to_s,
            webhookStatus: index_item.webhook_status.to_s,
            latestWebhookExecution: latest_webhook_execution(index_item, base_url),
            _links: links(index_item, base_url)

          }
        end

        def consumer_hash(index_item, _consumer, _consumer_version, base_url)
          {
            name: index_item.consumer_name,
            version: {
              number: index_item.consumer_version_number,
              branch: index_item.consumer_version_branches.last,
              headBranchNames: index_item.consumer_version_branches,
              _links: {
                self: {
                  href: version_url(base_url, index_item.consumer_version)
                }
              }
            },
            _links: {
              self: {
                href: pacticipant_url(base_url, index_item.consumer)
              }
            }
          }
        end

        def provider_hash(index_item, _provider, base_url)
          hash = {
            name: index_item.provider_name,
            version: nil,
            _links: {
              self: {
                href: pacticipant_url(base_url, index_item.provider)
              }
            }
          }

          if index_item.latest_verification
            hash[:version] = {
              number: index_item.provider_version_number,
              branch: index_item.provider_version_branches.last,
              headBranchNames: index_item.provider_version_branches
            }
          end

          hash
        end

        def pact_hash(index_item, base_url)
          {
            createdAt: format_date_time(index_item.latest_pact.created_at),
            _links: {
              self: {
                href: pact_url(base_url, index_item.latest_pact)
              }
            }
          }
        end

        def verification_hash(index_item, base_url)
          # Use the 'latest pact' URL instead of the permalink URL so that the page can be
          # refreshed, and the latest verification result will be updated to the  most recent
          if index_item.latest_verification
            {
              success: index_item.latest_verification.success,
              verifiedAt: format_date_time(index_item.latest_verification.created_at),
              _links: {
                self: {
                  href: latest_verification_for_pact_url(index_item.latest_pact, base_url, false)
                }
              }
            }
          else
            nil
          end
        end

        def pact_tags(index_item, base_url)
          index_item.tag_names.sort.collect do | tag_name |
            fake_tag = OpenStruct.new(name: tag_name, version: index_item.consumer_version)
            {
              name: tag_name,
              latest: true,
              _links: {
                self: {
                  href: tag_url(base_url, fake_tag)
                }
              }
            }
          end
        end

        def verification_tags(index_item, base_url)
          index_item.latest_verification_latest_tags.sort{ |t1, t2| t1.name <=> t2.name }.collect do | tag |
            fake_tag = OpenStruct.new(name: tag.name, version: index_item.provider_version)
            {
              name: tag.name,
              latest: tag.latest?,
              _links: {
                self: {
                  href: tag_url(base_url, fake_tag)
                }
              }
            }
          end
        end

        def latest_webhook_execution(index_item, _base_url)
          if index_item.last_webhook_execution_date
            {
              triggeredAt: format_date_time(index_item.last_webhook_execution_date)
            }
          end
        end

        def links(index_item, base_url)
          {
            "pb:webhook-status" => {
              title: "Status of webhooks for #{index_item.consumer_name}/#{index_item.provider_name} pact",
              href: webhooks_status_url(index_item.consumer, index_item.provider, base_url)
            }
          }
        end
      end
    end
  end
end
