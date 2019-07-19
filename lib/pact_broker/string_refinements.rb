module PactBroker
  module StringRefinements
    refine String do
      def not_blank?
        !blank?
      end

      def blank?
        self.strip.size == 0
      end
    end
  end
end