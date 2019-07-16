module PactBroker
  module HashRefinements
    refine Hash do
      def deep_merge(other_hash, &block)
        block_actual = Proc.new {|key, oldval, newval|
            newval = block.call(key, oldval, newval) if block_given?
            [oldval, newval].all? {|v| v.is_a?(Hash)} ? oldval.merge(newval, &block_actual) : newval
        }
        merge(other_hash, &block_actual)
      end
    end
  end
end
