module Expgen
  NON_LITERALS = "[]\^$.|?*+()".split("").map { |l| "\\" + l }.join

  module Parser
    class Repeat < Parslet::Parser
      rule(:lcurly)     { str('{') }
      rule(:rcurly)     { str('}') }
      rule(:multiply)   { str('*') }
      rule(:plus)       { str('+') }
      rule(:comma)      { str(',') }
      rule(:questionmark) { str('?') }

      rule(:integer) { match('[0-9]').repeat(1).as(:int) }

      rule(:amount) { lcurly >> integer.as(:repeat) >> (comma >> integer.as(:max).maybe).maybe >> rcurly }
      rule(:repeat) { plus.as(:repeat) | multiply.as(:repeat) | questionmark.as(:optional) | amount }

      root(:repeat)
    end

    class EscapeChar < Parslet::Parser
      rule(:backslash)  { str('\\') }

      rule(:code_point_octal) { backslash >> match["0-7"].repeat(3,3).as(:code) >> Repeat.new.maybe }
      rule(:code_point_hex) { backslash >> str("x") >> match["0-9a-fA-F"].repeat(2,2).as(:code) >> Repeat.new.maybe }
      rule(:code_point_unicode) { backslash >> str("u") >> match["0-9a-fA-F"].repeat(4,4).as(:code) >> Repeat.new.maybe }
      rule(:escape_char_control) { backslash >> match["nsrtvfae"].as(:letter) >> Repeat.new.maybe }
      rule(:escape_char_literal) { backslash >> any.as(:letter) >> Repeat.new.maybe }

      rule(:escape_char) { escape_char_control.as(:escape_char_control) | code_point_octal.as(:code_point_octal) | code_point_hex.as(:code_point_hex) | code_point_unicode.as(:code_point_unicode) | escape_char_literal.as(:escape_char_literal) }
      root(:escape_char)
    end

    class ShorthandCharacterClass < Parslet::Parser
      rule(:backslash)  { str('\\') }

      rule(:char_class_shorthand) { (backslash >> match["wWdDhHsS"].as(:letter) >> Repeat.new.maybe).as(:char_class_shorthand) }

      root(:char_class_shorthand)
    end

    class CharacterClass < Parslet::Parser
      rule(:dash)       { str('-') }
      rule(:lbracket)   { str('[') }
      rule(:rbracket)   { str(']') }

      rule(:alpha) { match["a-z"] }
      rule(:number) { match["0-9"] }
      rule(:char) { match["^\\[\\]"].as(:letter) }
      rule(:wildcard) { str('.').as(:wildcard) }
      rule(:range) { (alpha.as(:from) >> dash >> alpha.as(:to)) | (number.as(:from) >> dash >> number.as(:to)) }
      rule(:bracket_expression) { str("[:") >> alpha.repeat(1).as(:name) >> str(":]") }

      rule(:contents) { ShorthandCharacterClass.new | EscapeChar.new | range.as(:char_class_range) | char.as(:char_class_literal) | bracket_expression.as(:bracket_expression) }
      rule(:negative) { match["\\^"] }

      rule(:char_class) { (lbracket >> negative.maybe.as(:negative) >> contents.repeat.as(:groups) >> rbracket >> Repeat.new.maybe).as(:char_class) }
      root(:char_class)
    end

    class Expression < Parslet::Parser
      rule(:lparen)     { str('(') }
      rule(:rparen)     { str(')') }
      rule(:pipe)       { str('|') }
      rule(:backslash)  { str('\\') }

      rule(:literal) { match["^#{NON_LITERALS}"].as(:letter) >> Repeat.new.maybe  }

      rule(:wildcard) { str('.').as(:wildcard) >> Repeat.new.maybe }

      rule(:non_capturing) { str('?:') | str("?-mix:") }
      rule(:group) { lparen >> non_capturing.maybe >> expression.as(:elements) >> rparen >> Repeat.new.maybe }

      rule(:thing) { anchor | ShorthandCharacterClass.new | EscapeChar.new | wildcard.as(:wildcard) | literal.as(:literal) | group.as(:group) | CharacterClass.new }
      rule(:things) { thing.repeat(1) }

      rule(:anchor) { str("^") | str("$") | backslash >> match["bBAzZ"] }

      rule(:alternation) { things.as(:alt) >> (pipe >> things.as(:alt)).repeat(1) }

      rule(:expression) { alternation.as(:alternation) | things }
      root(:expression)
    end
  end
end
