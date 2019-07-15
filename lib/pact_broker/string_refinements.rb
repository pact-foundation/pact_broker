module PactBroker
  module StringRefinements
    refine String do
      def not_blank?
        self && self.strip.size > 0
      end
    end
  end
end