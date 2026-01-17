require "rspec/pact/matchers/version"
require "pact/support"
require "term/ansicolor"
require "rspec/matchers"

RSpec::Matchers.define :match_pact do |expected, options = {}|

  match do |actual|
    @diff = Pact::Matchers.diff(expected, actual, options)
    @diff.empty?
  end

  failure_message do |actual|
    formatted_diff = Pact::Matchers::UnixDiffFormatter.call(@diff, :colour => true)
    colorize(formatted_diff)
  end

  failure_message_when_negated do |actual|
    "Expected #{actual} to not match #{expected} but it did."
  end

  def colorize(s)
    s.split("\n").collect do |line|
      ::Term::ANSIColor.reset + line
    end.join("\n")
  end
end
