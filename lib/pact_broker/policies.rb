require 'pact_broker/configuration'

module PactBroker
  class DefaultPolicy
    def initialize(current_user, resource)
      @current_user = current_user
      @resource = resource
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

    def view?
      true
    end

    private

    attr_reader :current_user, :resource

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

  def self.policy!(*args)
    PactBroker.configuration.policy_builder.call(*args)
  end

  def self.policy_scope!(*args)
    PactBroker.configuration.policy_scope_builder.call(*args)
  end
end
