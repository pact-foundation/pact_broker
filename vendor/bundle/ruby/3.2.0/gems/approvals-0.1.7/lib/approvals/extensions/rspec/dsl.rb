require 'rspec/expectations'

module Approvals
  module RSpec
    module DSL
      def executable(command, &block)
        Approvals::Executable.new(command, &block)
      end

      def verify(options = {}, &block)
        # Workaround to support both Rspec 2 and 3
        # RSpec.current_example is the Rspec 3 way
        fetch_current_example = ::RSpec.respond_to?(:current_example) ? proc { ::RSpec.current_example } : proc { |context| context.example }
        # /Workaround

        group = eval "self", block.binding
        namer = ::RSpec.configuration.approvals_namer_class.new(fetch_current_example.call(group))
        defaults = {
          :namer => namer
        }
        format = ::RSpec.configuration.approvals_default_format
        defaults[:format] = format if format
        Approvals.verify(block.call, defaults.merge(options))
      rescue ApprovalError => e
        if diff_on_approval_failure?
          ::RSpec::Expectations.fail_with(e.message, e.approved_text, e.received_text)
        else
          raise e
        end
      end

      private

      def diff_on_approval_failure?
        # Workaround to support both RSpec 2 and 3
        fetch_current_example = ::RSpec.respond_to?(:current_example) ? proc { ::RSpec.current_example } : proc { |context| context.example }
        # /Workaround

        ::RSpec.configuration.diff_on_approval_failure? ||
          fetch_current_example.call(self).metadata[:diff_on_approval_failure]
      end
    end
  end
end
