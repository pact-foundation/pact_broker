module Approvals
  module Reporters
    class Reporter

      attr_reader :launcher

      def initialize(&launcher)
        @launcher = launcher || default_launcher
      end

      def report(received, approved)
        launch(received, approved)
      end

      def approved_when_reported?
        false
      end

      def default_launcher
        Launcher.opendiff
      end

      protected

      def launch(received, approved)
        `#{launcher.call(received, approved)}`
      end
    end
  end
end
