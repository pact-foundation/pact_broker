# PACT-7218: Deadlock Fixes

## Context

Three distinct production deadlocks. All occur under concurrent requests. Retry is ruled out as a fix.

---

## Error 1 — `branch_versions` update ShareLock deadlock

**Endpoint:** `POST /contracts/publish`
**Site:** `branch_version_repository.rb:31:in 'block in add_branch'`

```
Process 6337 waits for ShareLock on transaction 19873136; blocked by process 6340.
Process 6340 waits for ShareLock on transaction 19873137; blocked by process 6337.
CONTEXT: while updating tuple (34,90) in relation 'branch_versions'
```

Two concurrent publishes both find the same existing `branch_versions` row and both call
`branch_version.update(updated_at: Sequel.datetime_class.now)`. Mutual ShareLock → deadlock.

The `updated_at` touch when the row already exists is cosmetic — not load-bearing for correctness.

**Fix:** Drop the update. When `branch_version` already exists, just return it.

**Files (identical change in both):**
- `pact_broker_fork/lib/pact_broker/versions/branch_version_repository.rb`
- `lib/pact_broker/versions/branch_version_repository.rb` (OSS)

```ruby
# Before (lines 29-31):
if branch_version
  PactBroker.logger.info("Updating branch version #{branch_version.inspect}, time: #{Time.now}")
  branch_version.update(updated_at: Sequel.datetime_class.now)
else

# After:
if branch_version
  PactBroker.logger.debug("Branch version already exists #{branch_version.inspect}")
else
```

---

## Error 2 — `versions` upsert tuple-lock deadlock

**Endpoint:** `POST /contracts/publish`
**Site:** `sequel/plugins/upsert.rb:23` via `versions/repository.rb:106`

```
Process 12668 waits for ShareLock on transaction 18267088; blocked by process 12656.
Process 12656 waits for ShareLock on transaction 18267085; blocked by process 12670.
Process 12670 waits for AccessShareLock on tuple (125,10) of relation 'versions'; blocked by process 12668.
CONTEXT: while locking tuple (125,10) in relation 'versions'
```

Three concurrent publishes for the same consumer+version all see the `versions` row as absent (race),
fall into the `else` branch of `versions/repository.rb:create_or_update` (line 101), and call
`Version.new(...).upsert` (`INSERT ... ON CONFLICT DO UPDATE`). PostgreSQL's tuple-level locking
for `ON CONFLICT DO UPDATE` creates a 3-way cycle.

The upsert path is only reached when the initial SELECT returns nil — i.e. first publish of a
version, or three concurrent requests that all SELECT before any of them inserts.

**Fix:** Add `plugin :insert_ignore, identifying_columns: [:pacticipant_id, :number]` to `Version`
model and replace `Version.new(...).upsert` with `Version.new(...).insert_ignore` followed by a
separate `update` for mutable fields. `INSERT ... ON CONFLICT DO NOTHING` releases cleanly without
acquiring tuple locks on conflict; the subsequent `UPDATE WHERE id = ?` queues on a safe row-level
lock. Model hooks (`after_create` → `OrderVersions`) run correctly since `insert_ignore` goes
through `save`, not a raw dataset insert.

**Files:**
- `lib/pact_broker/domain/version.rb` — add `plugin :insert_ignore` with `identifying_columns: [:pacticipant_id, :number]`
- `lib/pact_broker/versions/repository.rb` — replace `upsert` in `create_or_update` with `insert_ignore` + separate `update`

```ruby
# Before (create_or_update else branch):
saved_version = PactBroker::Domain::Version.new(
  params.merge(pacticipant_id: pacticipant.id, number: version_number).compact
).upsert

# After:
insert_params = params.merge(pacticipant_id: pacticipant.id, number: version_number).compact
saved_version = PactBroker::Domain::Version.new(insert_params).insert_ignore
update_params = params.reject { |k, _| [:created_at, :order].include?(k) }
saved_version.update(update_params) if update_params.any?
```

---

## Error 3 — `triggered_webhooks` insert FOR KEY SHARE deadlock on `pacticipants`

**Endpoint:** `POST /pacts/.../verification_results`
**Site:** `trigger_service.rb:73` → `webhook_repository.create_triggered_webhook` → `TriggeredWebhook.create`

```
Process 4900 waits for ShareLock on transaction 1573262758; blocked by process 5594.
Process 5594 waits for ShareLock on transaction 1573262665; blocked by process 4900.
CONTEXT: while locking tuple (21,18) in relation 'pacticipants'
SQL: SELECT 1 FROM "pacticipants" WHERE "id" = $1 FOR KEY SHARE
```

`triggered_webhooks` has `consumer_id` and `provider_id` FKs → `pacticipants`. Inserting a
`triggered_webhooks` row acquires `FOR KEY SHARE` on both pacticipant rows inside the outer Rack
transaction. Two concurrent verifications for the same consumer/provider deadlock on each other's lock.

**Call chain:**
```
Rack::PactBroker::DatabaseTransaction    ← outer tx; locks held until commit
  verifications/service.rb:57 create
    verifications/service.rb:123 broadcast_events
      webhooks/event_listener.rb:43 provider_verification_published
        webhooks/event_listener.rb:74 handle_event_for_webhook
          trigger_service.rb:21 create_triggered_webhooks_for_event
            trigger_service.rb:66-73 create_triggered_webhooks_for_webhooks
              webhook_repository.create_triggered_webhook   ← FOR KEY SHARE on pacticipants
```

**Fix:** Defer `TriggeredWebhook.create` to run after the response is sent, outside the Rack
transaction, using `rack.after_reply`. The deferral point is `webhooks/event_listener.rb` —
instead of calling `create_triggered_webhooks_for_event` immediately in `handle_event_for_webhook`,
register an `after_reply` callback. The `rack_env` is already available via `webhook_options`.

**Files:**
- `lib/pact_broker/webhooks/event_listener.rb` — defer `create_triggered_webhooks_for_event` to after_reply
- `lib/pact_broker/async/after_reply.rb` — `rack.after_reply` / synchronous fallback wrapper
- `spec/lib/pact_broker/webhooks/event_listener_spec.rb` — test the deferral

---

## Verification

1. `bundle exec rspec` in `~/code/pact_broker` — all tests pass
2. No approval fixture changes expected for Error 1
3. Approval fixtures for verification-result endpoints may need updating for Error 3
4. Production signal: deadlock errors on `branch_versions` stop (Error 1); deadlock errors on
   `pacticipants` from verifications stop (Error 3)
