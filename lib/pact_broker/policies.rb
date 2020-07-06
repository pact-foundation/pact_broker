module PactBroker
  class DefaultPolicy
    def initialize(user, something)
      @user = user
      @something = something
    end

    def update?
      true
    end

    def delete?
      true
    end

    def create?
      true
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        scope
      end

      private

      attr_reader :user, :scope
    end
  end

  def self.policy_scope!(scope)
    scope
  end
end
