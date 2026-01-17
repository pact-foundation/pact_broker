module Approvals
  module Reporters
    class FirstWorkingReporter

      attr_accessor :reporters
      def initialize(*reporters)
        self.reporters = reporters
      end

      def working_in_this_environment?
        reporters.any?(&:working_in_this_environment?)
      end

      def report(received, approved)
        reporter = reporters.find(&:working_in_this_environment?)
        reporter.report(received, approved) unless reporter.nil?
      end

    end
  end
end
