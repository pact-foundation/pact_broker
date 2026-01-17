require "parslet"
require "expgen/version"
require "expgen/parser"
require "expgen/transform"
require "expgen/randomizer"
require "expgen/nodes"

module Expgen
  ASCII = (32..126).map(&:chr)
  LOWER = ("a".."z").to_a
  UPPER = ("A".."Z").to_a
  DIGIT = (0..9).map(&:to_s)
  ALPHA = LOWER + UPPER
  WORD = ALPHA + DIGIT + ["_"]
  NEGATIVE_WORD = ASCII - WORD
  NON_DIGIT = ASCII - DIGIT
  HEX_DIGIT = ("a".."f").to_a + ("A".."F").to_a + DIGIT
  NON_HEX_DIGIT = ASCII - HEX_DIGIT
  SPACE = [" "]
  NON_SPACE = ASCII.drop(1)
  CONTROL_CHARS = (0.chr..31.chr).to_a
  PUNCT = (33..47).map(&:chr) + (58..64).map(&:chr) + (91..96).map(&:chr) + (123..126).map(&:chr)

  ESCAPE_CHARS = { "n" => "\n", "s" => "\s", "r" => "\r", "t" => "\t", "v" => "\v", "f" => "\f", "a" => "\a", "e" => "\e" }

  class ParseError < StandardError; end

  def self.cache
    @cache ||= {}
  end

  def self.clear_cache
    @cache = nil
  end

  def self.gen(exp)
    source = if exp.respond_to?(:source) then exp.source else exp.to_s end
    cache[source] ||= Transform.new.apply((Parser::Expression.new.parse(source)))
    Randomizer.randomize(cache[source])
  rescue Parslet::ParseFailed => e
    raise Expgen::ParseError, e.message
  end
end
