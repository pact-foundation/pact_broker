# Pact::Doc

The code in pact/doc has been copied from the pact gem to break the runtime dependency between the pact_broker and the pact gem, which requires the pact_mock-service, which requires webrick.

This was required as there is a vulnerability in webrick <= 1.3.1 that we don't want to include in the pact_broker gem, but webrick > 1.3.1 requires ruby 2.3.0, but we need ruby 2.2 for Travelling Ruby, which we use to package the Ruby codebase so it can be shared with implementations in other langauges.