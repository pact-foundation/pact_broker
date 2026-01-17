# frozen_string_literal: true

module OpenapiFirst
  module Test
    class ObserveError < Error; end

    # @visible private
    module Observed; end

    # Inject silent request/response validation to observe rack apps during testing
    module Observe
      def self.observe(app, api: :default)
        definition = OpenapiFirst::Test[api]
        mod = OpenapiFirst::Test::Callable[definition]

        if app.respond_to?(:call)
          return if app.singleton_class.include?(Observed)

          app.singleton_class.prepend(mod)
          app.singleton_class.include(Observed)
          return
        end

        unless app.instance_methods.include?(:call)
          raise ObserveError, "Don't know how to observe #{app}, because it has no call instance method."
        end

        return if app.include?(Observed)

        app.prepend(mod)
        app.include(Observed)
      end
    end
  end
end
