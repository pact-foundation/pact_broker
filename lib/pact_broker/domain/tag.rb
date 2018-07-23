require 'pact_broker/db'
require 'pact_broker/repositories/helpers'

module PactBroker

  module Domain
    class Tag < Sequel::Model

      dataset_module do
        include PactBroker::Repositories::Helpers
      end

      unrestrict_primary_key

      associate(:many_to_one, :version, :class => "PactBroker::Domain::Version", :key => :version_id, :primary_key => :id)

      def <=> other
        name <=> other.name
      end

    end

    Tag.plugin :timestamps, :update_on_create=>true
  end
end

# Table: tags
# Primary Key: (name, version_id)
# Columns:
#  name       | text                        |
#  version_id | integer                     |
#  created_at | timestamp without time zone | NOT NULL
#  updated_at | timestamp without time zone | NOT NULL
# Indexes:
#  tags_pk      | PRIMARY KEY btree (version_id, name)
#  ndx_tag_name | btree (name)
# Foreign key constraints:
#  tags_version_id_fkey | (version_id) REFERENCES versions(id)
