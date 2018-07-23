require 'pact_broker/db'
require 'pact_broker/messages'
require 'pact_broker/repositories/helpers'

module PactBroker

  module Domain

    class Pacticipant < Sequel::Model

      include Messages

      set_primary_key :id

      one_to_many :versions, :order => :order, :reciprocal => :pacticipant
      one_to_many :labels, :order => :name, :reciprocal => :pacticipant
      one_to_many :pacts

      dataset_module do
        include PactBroker::Repositories::Helpers

        def label label_name
          filter = name_like(Sequel[:labels][:name], label_name)
          join(:labels, {pacticipant_id: :id}).where(filter)
        end
      end

      def latest_version
        versions.last
      end

      def to_s
        "Pacticipant: id=#{id}, name=#{name}"
      end

      def validate
        messages = []
        messages << message('errors.validation.attribute_missing', attribute: 'name') unless name
        messages
      end
    end

    Pacticipant.plugin :timestamps, update_on_create: true
  end
end

# Table: pacticipants
# Columns:
#  id             | integer                     | PRIMARY KEY DEFAULT nextval('pacticipants_id_seq'::regclass)
#  name           | text                        |
#  repository_url | text                        |
#  created_at     | timestamp without time zone | NOT NULL
#  updated_at     | timestamp without time zone | NOT NULL
# Indexes:
#  pacticipants_pkey     | PRIMARY KEY btree (id)
#  pacticipants_name_key | UNIQUE btree (name)
#  ndx_ppt_name          | btree (name)
# Referenced By:
#  pact_publications  | pact_publications_provider_id_fkey  | (provider_id) REFERENCES pacticipants(id)
#  pact_versions      | pact_versions_consumer_id_fkey      | (consumer_id) REFERENCES pacticipants(id)
#  pact_versions      | pact_versions_provider_id_fkey      | (provider_id) REFERENCES pacticipants(id)
#  versions           | versions_pacticipant_id_fkey        | (pacticipant_id) REFERENCES pacticipants(id)
#  labels             | labels_pacticipant_id_fkey          | (pacticipant_id) REFERENCES pacticipants(id)
#  triggered_webhooks | triggered_webhooks_consumer_id_fkey | (consumer_id) REFERENCES pacticipants(id)
#  triggered_webhooks | triggered_webhooks_provider_id_fkey | (provider_id) REFERENCES pacticipants(id)
#  webhook_executions | webhook_executions_consumer_id_fkey | (consumer_id) REFERENCES pacticipants(id)
#  webhook_executions | webhook_executions_provider_id_fkey | (provider_id) REFERENCES pacticipants(id)
#  webhooks           | fk_webhooks_consumer                | (consumer_id) REFERENCES pacticipants(id)
#  webhooks           | fk_webhooks_provider                | (provider_id) REFERENCES pacticipants(id)
