# frozen_string_literal: true

module Dry
  module Schema
    # @api private
    class PrimitiveInferrer < ::Dry::Types::PrimitiveInferrer
      Compiler = ::Class.new(superclass::Compiler) do
        # @api private
        def visit_intersection(node)
          left, right = node
          [visit(left), visit(right)].flatten(1)
        end
      end

      def initialize
        super

        @compiler = Compiler.new
      end
    end
  end
end
