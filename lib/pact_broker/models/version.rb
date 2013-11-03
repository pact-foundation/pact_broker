require 'sequel'

module PactBroker

  module Models

    class Version < Sequel::Model

      one_to_many :pacts

      def to_s
        "Version: number=#{number}, pacticipant=#{pacticipant_id}"
      end
    end
  end
end