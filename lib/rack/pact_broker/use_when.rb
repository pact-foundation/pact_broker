=begin

Conditionally use Rack Middleware.

Usage:

condition_proc = ->(env) { env['PATH_INFO'] == '/match' }
use_when condition_proc, SomeMiddleware, options

I feel sure there must be something like this officially supported somewhere, but I can't find it.

=end

module Rack
  module PactBroker
    module UseWhen
      class ConditionallyUseMiddleware
        def initialize(app, condition_proc, middleware, *args, **kwargs, &block)
          @app_without_middleware = app
          @condition_proc = condition_proc
          @middleware = middleware
          @args = args
          @kwargs = kwargs
          @block = block
        end

        def call(env)
          if condition_proc.call(env)
            app_with_middleware.call(env)
          else
            app_without_middleware.call(env)
          end
        end

        private

        attr_reader :app_without_middleware, :condition_proc, :middleware, :args, :kwargs, :block

        def app_with_middleware
          @app_with_middleware ||= begin
            rack_builder = ::Rack::Builder.new
            rack_builder.use middleware, *args, **kwargs, &block
            rack_builder.run app_without_middleware
            rack_builder.to_app
          end
        end
      end

      refine Rack::Builder do
        def use_when(condition_proc, middleware, *args, **kwargs, &block)
          use(ConditionallyUseMiddleware, condition_proc, middleware, *args, **kwargs, &block)
        end
      end
    end
  end
end
