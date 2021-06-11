module PactBroker
  module StringRefinements
    refine NilClass do
      def blank?
        true
      end
    end

    refine String do
      def not_blank?
        !blank?
      end

      def blank?
        self.strip.size == 0
      end

      # ripped from rubyworks/facets, thank you
      def snakecase
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        .gsub(/([a-z\d])([A-Z])/,'\1_\2')
        .tr("-", "_")
        .gsub(/\s/, "_")
        .gsub(/__+/, "_")
        .downcase
      end

      # ripped from rubyworks/facets, thank you
      def camelcase(*separators)
        case separators.first
        when Symbol, TrueClass, FalseClass, NilClass
          first_letter = separators.shift
        end

        separators = ["_", '\s'] if separators.empty?

        str = self.dup

        separators.each do |s|
          str = str.gsub(/(?:#{s}+)([a-z])/){ $1.upcase }
        end

        case first_letter
        when :upper, true
          str = str.gsub(/(\A|\s)([a-z])/){ $1 + $2.upcase }
        when :lower, false
          str = str.gsub(/(\A|\s)([A-Z])/){ $1 + $2.downcase }
        end

        str
      end
    end
  end
end
