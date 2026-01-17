module Approvals
  module Reporters
    class VimdiffReporter < Reporter
      include Singleton

      class << self
        def report(received, approved)
          self.instance.report(received, approved)
        end
      end

      def default_launcher
        Launcher.vimdiff
      end

    end
  end
end
