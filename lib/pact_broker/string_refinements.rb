module PactBroker
  module StringRefinements
    refine TrueClass do
      def blank?
        false
      end

      def present?
        true
      end
    end

    refine FalseClass do
      def blank?
        false
      end

      def present?
        true
      end
    end

    refine NilClass do
      def blank?
        true
      end

      def present?
        false
      end
    end

    refine Numeric do
      def blank?
        false
      end
    end

    refine String do
      def integer?
        self =~ /^\d+$/
      end

      def present?
        !blank?
      end

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

      def dasherize
        snakecase.tr("_", "-")
      end

      # ripped from rubyworks/facets, thank you
      def camelcase(*separators)
        case separators.first
        when Symbol, TrueClass, FalseClass, NilClass
          first_letter = separators.shift
        end

        separators = ["_", "\\s"] if separators.empty?

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

      # Adopt from https://stackoverflow.com/questions/1451384/how-can-i-center-truncate-a-string
      def ellipsisize(minimum_length: 20, edge_length: 10)
        return self if self.length < minimum_length || self.length <= edge_length * 2

        edge = "." * edge_length
        mid_length = self.length - edge_length * 2
        gsub(/(#{edge}).{#{mid_length},}(#{edge})/, '\1...\2')
      end
    end
  end
end
