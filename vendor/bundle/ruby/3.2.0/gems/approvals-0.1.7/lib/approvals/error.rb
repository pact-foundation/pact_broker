module Approvals
  class ApprovalError < Exception
    attr_accessor :received_path, :approved_path

    def received_exists?
      received_path && File.exist?(received_path)
    end

    def received_text
      received_exists? && IO.read(received_path)
    end

    def approved_exists?
      approved_path && File.exist?(approved_path)
    end

    def approved_text
      approved_exists? && IO.read(approved_path)
    end
  end
end
