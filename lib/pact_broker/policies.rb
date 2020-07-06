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

  def self.current_user
    @current_user ||= OpenStruct.new
  end

  def self.policy_scope!(scope)
    DefaultPolicy::Scope.new(current_user, scope).resolve
  end
end
