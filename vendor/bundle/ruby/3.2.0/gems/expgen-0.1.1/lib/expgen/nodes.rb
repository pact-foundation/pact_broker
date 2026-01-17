module Expgen
  module Nodes
    class Node
      attr_reader :ast

      def initialize(ast)
        @ast = ast
      end

      def repeat
        ast[:repeat]
      end

      def max
        ast[:max]
      end
    end

    class Group < Node
      def elements
        ast[:elements]
      end
    end

    class Alternation < Node
      def options
        ast.map { |option| option[:alt] }
      end
    end

    class Character < Node; end

    class CharacterClass < Character
      def groups
        ast[:groups]
      end

      def chars
        chars = groups.map(&:chars).flatten
        val = if ast[:negative]
          ASCII - chars
        else
          chars
        end
      end
    end

    class Literal < Character
      def chars
        [ast[:letter].to_s]
      end
    end

    class Wildcard < Character
      def chars
        ASCII
      end
    end

    class Shorthand < Character
      def chars
        case ast[:letter].to_s
          when "w" then WORD
          when "W" then NEGATIVE_WORD
          when "d" then DIGIT
          when "D" then NON_DIGIT
          when "h" then HEX_DIGIT
          when "H" then NON_HEX_DIGIT
          when "s" then SPACE
          when "S" then NON_SPACE
        end
      end
    end

    class BracketExpression < Character
      def chars
        case ast[:name].to_s
          when "alnum" then ALPHA + DIGIT
          when "alpha" then ALPHA
          when "blank" then " "
          when "cntrl" then CONTROL_CHARS
          when "digit" then DIGIT
          when "graph" then NON_SPACE
          when "lower" then LOWER
          when "print" then ASCII
          when "punct" then PUNCT
          when "space" then SPACE
          when "upper" then UPPER
          when "xdigit" then HEX_DIGIT
          when "word" then WORD + ["_"]
          when "ascii" then ASCII
        end
      end
    end

    class Range < Character
      def chars
        (ast[:from].to_s..ast[:to].to_s).to_a
      end
    end

    class EscapeCharControl < Character
      def chars
        [ESCAPE_CHARS[ast[:letter].to_s]]
      end
    end

    class EscapeCharLiteral < Character
      def chars
        [ast[:letter].to_s]
      end
    end

    class CodePointOctal < Character
      def chars
        [ast[:code].to_s.to_i(8).chr]
      end
    end

    class CodePointHex < Character
      def chars
        [ast[:code].to_s.to_i(16).chr]
      end
    end

    class CodePointUnicode < Character
      def chars
        [ast[:code].to_s.to_i(16).chr("UTF-8")]
      end
    end
  end
end
