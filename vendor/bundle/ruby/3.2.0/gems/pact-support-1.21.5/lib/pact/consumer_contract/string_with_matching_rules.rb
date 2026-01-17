module Pact
  class StringWithMatchingRules < String
    attr_reader :matching_rules
    attr_reader :pact_specification_version

    def initialize string, pact_specification_version, matching_rules = {}
      super(string)
      @matching_rules = matching_rules
      @pact_specification_version = pact_specification_version
    end

    # How can we show the matching rules too?
    def to_s
      super
    end
  end
end
