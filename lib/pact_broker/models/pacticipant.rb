require 'pact_broker/db'

module PactBroker

  module Models

    class Pacticipant < Sequel::Model

      set_primary_key :id

      one_to_many :versions, :order => :order, :reciprocal => :pacticipant
      one_to_many :pacts

      def latest_version
        versions.last
      end

      def to_s
        "Pacticipant: id=#{id}, name=#{name}"
      end
    end

    Pacticipant.plugin :timestamps, :update_on_create=>true
  end
end