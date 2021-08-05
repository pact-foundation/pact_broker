module PactBroker
  module Repositories
    module Scopes
      def with_no_scope
        @unscoped = true
        yield self
      ensure
        @unscoped = false
      end

      def scope_for(scope)
        if @unscoped == true
          scope
        else
          PactBroker.policy_scope!(scope)
        end
      end

      # For the times when it doesn't make sense to use the scoped class, this is a way to
      # indicate that it is an intentional use
      def unscoped(scope)
        scope
      end
    end
  end
end
