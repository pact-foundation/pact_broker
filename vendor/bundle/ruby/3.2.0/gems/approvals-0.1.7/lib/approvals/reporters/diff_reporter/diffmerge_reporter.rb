module Approvals
  module Reporters
    class DiffmergeReporter < Reporter
      include Singleton

      class << self
        def report(received, approved)
          self.instance.report(received, approved)
        end
      end

      def default_launcher
        Launcher.diffmerge
      end

    end
  end
end
