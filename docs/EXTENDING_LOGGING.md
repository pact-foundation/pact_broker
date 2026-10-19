# Extending the Pact Broker's logging

The Pact Broker uses [Semantic Logger](https://github.com/reidmorrison/semantic_logger).
This page covers the three extension points available to an application that
builds on the Pact Broker.

## Adding log destinations

Use the `log_appenders` configuration setting. See
[CONFIGURATION.md](CONFIGURATION.md#log_appenders) for the full schema. Any
Semantic Logger appender can be used, and any appender specific option is passed
through:

```yaml
log_appenders:
  - stream: stdout
    format: json
  - appender: open_telemetry
    enabled: auto
```

Set `enabled: auto` for an appender whose gem is optional. The appender is added
when the gem is available, and skipped without error when it is not.

## Adding fields to every log entry

Register a context provider. Providers run once per log entry, before the entry
reaches the appenders, so the fields they contribute appear in every format -
JSON, human readable, and any other appender.

```ruby
require "pact_broker/logging/context"

PactBroker::Logging::Context.register_provider(:tenant) do
  { tenant_id: MyApp::Tenant.current&.id }
end
```

A provider is anything responding to `#call` with no arguments, returning a Hash
of named tags, or nil to contribute nothing. Providers are keyed by name, so
registering the same name again replaces the previous provider. That makes
registration safe to repeat, and lets you replace a built-in provider such as
`:trace`.

Notes:

* Tags set explicitly with `SemanticLogger.tagged` take precedence over provider
  values.
* A provider that raises is reported once on `$stderr` and then ignored. It
  cannot break logging.
* Providers run on every log entry, so keep them cheap and non-blocking.

To hide a tag from the compact `short` development format:

```ruby
SemanticLogger::Formatters::Short.hidden_named_tags += [:tenant_id]
```

## Keeping context across async work

Named tags are thread local and block scoped, so they are gone by the time a
background job or an after-reply callback runs. Capture them where the context
exists, and restore them where the work happens:

```ruby
require "pact_broker/logging/tag_propagation"

tags = PactBroker::Logging::TagPropagation.capture

do_work_later do
  PactBroker::Logging::TagPropagation.with(tags) do
    # log entries in here carry the original request_id
  end
end
```

Trace context is deliberately not captured this way. It is contributed by a
context provider at the moment each entry is logged, so work that runs long after
the original request reports whatever span is genuinely active instead of
resurrecting a closed trace.

## Trace correlation and OpenTelemetry

The Pact Broker never starts a trace, and never reads `traceparent` from an
inbound request. The built-in `:trace` context provider only reads whichever
span OpenTelemetry reports as currently active, and contributes nothing when the
OpenTelemetry gems are not loaded.

Distributed tracing - continuing a caller's trace, and parenting spans correctly
- is therefore the embedding application's responsibility. Install and configure
`opentelemetry-sdk` along with Rack instrumentation, and the `trace_id`,
`span_id` and `trace_flags` tags start appearing on log entries with no further
wiring. This applies to async work too: a background job reports the span that is
active when it runs.

Request correlation is independent of all of this. The `request_id` tag is always
present, whether or not OpenTelemetry is in use. It is taken from the inbound
`X-Request-Id` header, falling back to `X-Correlation-Id`, and is generated when
neither is present or the supplied value is not a safe token. The resolved value
is returned in the `x-request-id` response header, and is propagated to
background jobs and after-reply callbacks.
