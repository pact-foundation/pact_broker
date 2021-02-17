require 'pact_broker/test/test_data_builder'
require 'pact_broker/pacticipants/service'

module PactBroker
  module DB
    class SeedExampleData
      CONSUMER_NAME = "Example App"
      PROVIDER_NAME = "Example API"

      def self.call
        new.call
      end

      def call(consumer_name: CONSUMER_NAME, provider_name: PROVIDER_NAME)
        return unless database_empty?
        PactBroker::Test::TestDataBuilder.new
          .create_environment("test", display_name: "Test", production: false)
          .create_environment("production", display_name: "Production", production: true)
          .create_consumer(consumer_name, created_at: days_ago(16))
          .create_provider(provider_name, created_at: days_ago(16))
          .create_consumer_version("e15da45d3943bf10793a6d04cfb9f5dabe430fe2", branch: "main", created_at: days_ago(16))
          .create_consumer_version_tag("prod", created_at: days_ago(16))
          .create_consumer_version_tag("main", created_at: days_ago(16))
          .create_deployed_version_for_consumer_version(environent_name: "production", currently_deployed: false, created_at: days_ago(16))
          .create_pact(json_content: pact_1, created_at: days_ago(16))
          .create_verification(provider_version: "1315e0b1924cb6f42751f977789be3559373033a", branch: "main", execution_date: days_ago(15))
          .create_deployed_version_for_consumer_version(environent_name: "production", currently_deployed: false, created_at: days_ago(14))
          .create_verification(provider_version: "480e5aeb30467856ca995d0024d2c1800b0719e5", branch: "main", success: false, number: 2, execution_date: days_ago(14))
          .create_provider_version_tag("main", created_at: days_ago(14))
          .create_consumer_version("725c6ccb7cf7efc51b4394f9828585eea9c379d9", branch: "feat/new-thing", created_at: days_ago(7))
          .create_consumer_version_tag("feat-new-thing", created_at: days_ago(7))
          .create_pact(json_content: pact_2, created_at: days_ago(7))
          .create_consumer_version("7bd4d9173522826dc3e8704fd62dde0424f4c827", branch: "main", created_at: days_ago(1))
          .create_consumer_version_tag("main", created_at: days_ago(1))
          .create_pact(json_content: pact_3, created_at: days_ago(1))
          .create_verification(provider_version: "4fdf20082263d4c5038355a3b734be1c0054d1e1", branch: "main", execution_date: days_ago(1))
          .create_provider_version_tag("main", created_at: days_ago(1))
          .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30", branch: "main", created_at: days_ago(0.5))
          .create_consumer_version_tag("main", created_at: days_ago(0.5))
          .republish_same_pact(created_at: days_ago(0.5))
      end

      def database_empty?
        PactBroker::Pacticipants::Service.find_all_pacticipants.empty?
      end

      def pact_1
        seed_data_file("pact_1.json")
      end

      def pact_2
        seed_data_file("pact_2.json")
      end

      def pact_3
        seed_data_file("pact_3.json")
      end

      def seed_data_dir
        File.join(File.dirname(__FILE__), "seed")
      end

      def seed_data_file(name)
        File.read(File.join(seed_data_dir, name))
      end

      def days_ago(days)
        DateTime.now - days
      end
    end
  end
end
