module PactBroker
  module Api
    module Resources
      module Authorization
        def action
          if read_methods.include?(request.method)
            :read
          elsif update_methods.include?(request.method)
            :update
          elsif create_methods.include?(request.method)
            :create
          elsif delete_methods.include?(request.method)
            :delete
          else
            raise "Cannot map #{request.method} to an action"
          end
        end

        def read_methods
          %w{GET HEAD OPTIONS}
        end

        def update_methods
          %w{PUT PATCH}
        end

        def create_methods
          %w{POST PUT}
        end

        def delete_methods
          %w{DELETE}
        end
      end
    end
  end
end
