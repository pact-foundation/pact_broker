module Approvals
  module Reporters
    class OpendiffReporter < Reporter
      include Singleton

      class << self
        def report(received, approved)
          self.instance.report(received, approved)
        end
      end

      def default_launcher
        Launcher.opendiff
      end

    end
  end
end
