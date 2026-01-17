# frozen_string_literal: true

module Dry
  module Schema
    # @api private
    class PredicateInferrer < ::Dry::Types::PredicateInferrer
      Compiler = ::Class.new(superclass::Compiler) do
        # @api private
        def visit_intersection(node)
          left_node, right_node, = node
          left = visit(left_node)
          right = visit(right_node)

          [left, right].flatten.compact
        end
      end

      def initialize(registry = PredicateRegistry.new)
        super

        @compiler = Compiler.new(registry)
      end
    end
  end
end
