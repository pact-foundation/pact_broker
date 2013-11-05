require 'sequel'

module PactBroker

  module Models

    class Pacticipant < Sequel::Model

      one_to_many :versions, :order => :id, :reciprocal => :pacticipant
      one_to_many :pacts

      def last_version
        versions.last
      end

      def to_s
        "Pacticipant: id=#{id}, name=#{name}"
      end
    end
  end
end