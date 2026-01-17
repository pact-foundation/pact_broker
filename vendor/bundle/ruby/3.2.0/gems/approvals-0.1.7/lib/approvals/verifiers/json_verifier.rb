module Approvals
  module Verifiers
    class JsonVerifier
      def initialize(received_path, approved_path)
        self.received_path = received_path
        self.approved_path = approved_path
      end

      def verify
        approved == received
      end

      private

      attr_accessor :approved_path, :received_path

      def approved
        JSON.parse(File.read(approved_path))
      end

      def received
        JSON.parse(File.read(received_path))
      end
    end
  end
end
