require 'sequel'

module PactBroker

  module Models

    class Pacticipant < Sequel::Model

      one_to_many :versions

      def to_s
        "Pacticipant: id=#{id}, name=#{name}"
      end
    end
  end
end