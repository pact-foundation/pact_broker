module PactBroker
  module Repositories
    module Scopes
      def scope_for(scope)
        PactBroker.policy_scope!(scope)
      end

      # For the times when it doesn't make sense to use the scoped class, this is a way to
      # indicate that it is an intentional use
      def unscoped(scope)
        scope
      end
    end
  end
end
