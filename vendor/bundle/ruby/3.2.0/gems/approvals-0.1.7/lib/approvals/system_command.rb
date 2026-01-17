module Approvals

  module SystemCommand

    class << self
      def exists?(executable)
        `which #{executable}` != ""
      end
    end

  end

end
