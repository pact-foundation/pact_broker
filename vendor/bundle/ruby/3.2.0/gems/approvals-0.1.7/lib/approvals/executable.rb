module Approvals
  class Executable

    attr_accessor :command, :on_failure
    def initialize(command, &block)
      self.command = command
      self.on_failure = block
    end

    def to_s
      inspect
    end

    def inspect
      command
    end
  end
end
