require "pact_broker/dataset"

module PactBroker
  module Domain
    class Label < Sequel::Model
      set_primary_key([:name, :pacticipant_id])
      unrestrict_primary_key

      plugin :timestamps, update_on_create: true

      associate(:many_to_one, :pacticipant, :class => "PactBroker::Domain::Pacticipant", :key => :pacticipant_id, :primary_key => :id)

      def <=> other
        name <=> other.name
      end

      dataset_module do
        include PactBroker::Dataset
      end
    end
  end
end

# Table: labels
# Primary Key: (name, pacticipant_id)
# Columns:
#  name           | text                        |
#  pacticipant_id | integer                     |
#  created_at     | timestamp without time zone | NOT NULL
#  updated_at     | timestamp without time zone | NOT NULL
# Indexes:
#  labels_pk | PRIMARY KEY btree (pacticipant_id, name)
# Foreign key constraints:
#  labels_pacticipant_id_fkey | (pacticipant_id) REFERENCES pacticipants(id)
