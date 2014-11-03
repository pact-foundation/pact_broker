require 'pact_broker/db'
require 'pact_broker/messages'

module PactBroker

  module Domain

    class Pacticipant < Sequel::Model

      include Messages

      set_primary_key :id

      one_to_many :versions, :order => :order, :reciprocal => :pacticipant
      one_to_many :pacts

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

    Pacticipant.plugin :timestamps, :update_on_create=>true
  end
end