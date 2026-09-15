module PactBroker
  # Keyword options for JSON.parse. Splat them (`**PACT_PARSING_OPTIONS`):
  # json 3 rejects a positional options hash.
  #
  # allow_duplicate_key keeps the last-key-wins behaviour that json 2
  # applied by default; json 3 rejects duplicate keys unless told otherwise.
  PACT_PARSING_OPTIONS = {
    max_nesting: 50,
    allow_duplicate_key: true
  }
end
