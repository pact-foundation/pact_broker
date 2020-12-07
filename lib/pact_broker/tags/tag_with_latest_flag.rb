require 'pact_broker/db'
require 'pact_broker/repositories/helpers'

module PactBroker
  module Tags
    # The tag associated with the latest verification for a given tag
    class TagWithLatestFlag < Sequel::Model(:tags_with_latest_flag)
      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      dataset_module do
        include PactBroker::Repositories::Helpers
      end

      def latest?
        !values[:latest].nil?
      end
    end
  end
end

# Table: tags_with_latest_flag
# Columns:
#  name       | text                        |
#  version_id | integer                     |
#  created_at | timestamp without time zone |
#  updated_at | timestamp without time zone |
#  latest     | integer                     |
