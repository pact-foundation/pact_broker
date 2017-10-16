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