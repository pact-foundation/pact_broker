
module PactBroker
  module Json
    PACT_PARSING_OPTIONS = {
      max_nesting: 50,
      create_additions: false
    }
  end
  
  # For backward compatibility, also expose at module level
  PACT_PARSING_OPTIONS = Json::PACT_PARSING_OPTIONS
end