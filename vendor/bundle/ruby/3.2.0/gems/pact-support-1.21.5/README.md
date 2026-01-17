# Pact Support
[![Gem Version](https://badge.fury.io/rb/pact-support.svg)](http://badge.fury.io/rb/pact-support)
![Build status](https://github.com/pact-foundation/pact-support/workflows/Test/badge.svg)
[![Join the chat at https://pact-foundation.slack.com/](https://img.shields.io/badge/chat-on%20slack-blue.svg?logo=slack)](https://slack.pact.io)

Provides shared code for the Pact gems

## Compatibility

<details><summary>Specification Compatibility</summary>

| Version  | Stable | [Spec] Compatibility | 
| -------  | ------ | -------------------- |
| 1.x.x    | Yes    | 2, 3\*               |

_\*_ v3 support is limited to the subset of functionality required to enable language inter-operable [Message support].

- See V3 tracking [issue](https://github.com/pact-foundation/pact-ruby/issues/318).
- See V4 tracking [issue](https://github.com/pact-foundation/pact-ruby/issues/319).

Want V3/V4 support now? See the new standalone [pact-verifier](https://github.com/pact-foundation/pact-reference/tree/master/rust/pact_verifier_cli#standalone-pact-verifier)

[message support]: https://github.com/pact-foundation/pact-specification/tree/version-3#introduces-messages-for-services-that-communicate-via-event-streams-and-message-queues

</details>

### Supported matching rules

| matcher       | Spec Version | Implemented | Usage|
|---------------|--------------|-------------|-------------|
| Equality      | V1           |   |    |
| Regex         | V2           | ✅  | `Pact.term(generate, matcher)` |
| Type          | V2           | ✅  | `Pact.like(generate)` |
| MinType       | V2           | ✅  | `Pact.each_like(generate, min: <val>)` |
| MaxType       | V2           |   |    |
| MinMaxType    | V2           |   |    |
| Include       | V3           |   |    |
| Integer       | V3           |   |    |
| Decimal       | V3           |   |    |
| Number        | V3           |   |    |
| Timestamp     | V3           |   |    |
| Time          | V3           |   |    |
| Date          | V3           |   |    |
| Null          | V3           |   |    |
| Boolean       | V3           |   |    |
| ContentType   | V3           |   |    |
| Values        | V3           |   |    |
| ArrayContains | V4           |   |    |
| StatusCode    | V4           |   |    |
| NotEmpty      | V4           |   |    |
| Semver        | V4           |   |    |
| EachKey       | V4           |   |    |
| EachValue     | V4           |   |    |

### Supported generators

Currently limited to provider verification only. No current way to set in consumer tests.

| Generator                | Spec Version | Implemented |
|------------------------|--------------|----|
| RandomInt              | V3           | ✅ |
| RandomDecimal          | V3           | ✅ |
| RandomHexadecimal      | V3           | ✅ |
| RandomString           | V3           | ✅ |
| Regex                  | V3           | ✅ |
| Uuid                   | V3/V4        | ✅ |
| Date                   | V3           | ✅ |
| Time                   | V3           | ✅ |
| DateTime               | V3           | ✅ |
| RandomBoolean          | V3           | ✅ |
| ProviderState          | V4           | ✅ |
| MockServerURL          | V4           | 🚧 |
