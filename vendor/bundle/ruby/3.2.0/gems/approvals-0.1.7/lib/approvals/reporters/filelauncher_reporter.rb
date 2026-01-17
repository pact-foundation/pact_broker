module Approvals
  module Reporters
    class FilelauncherReporter < Reporter
      include Singleton

      class << self
        def report(received, approved = nil)
          self.instance.report(received, approved)
        end
      end

      def default_launcher
        Launcher.filelauncher
      end

    end
  end
end
