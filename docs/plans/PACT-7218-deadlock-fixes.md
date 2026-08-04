# PACT-7218: Deadlock Fixes (Core)

Three distinct production deadlocks under concurrent `POST /contracts/publish` requests.
This branch (`fix/PACT-7218-deadlock-core`) addresses Errors 1 and 2 only.
Error 3 (webhook `FOR KEY SHARE` deadlock) is handled separately via after_reply deferral.

---

## Error 1 — `branch_versions` update ShareLock deadlock

**Site:** `lib/pact_broker/versions/branch_version_repository.rb` → `add_branch`

```
Process 6337 waits for ShareLock on transaction 19873136; blocked by process 6340.
Process 6340 waits for ShareLock on transaction 19873137; blocked by process 6337.
CONTEXT: while updating tuple (34,90) in relation 'branch_versions'
```

Two concurrent publishes both find the same existing `branch_versions` row and call
`branch_version.update(updated_at: ...)`. Mutual ShareLock → deadlock.

### Fix

When `branch_version` already exists, skip the update entirely. The `updated_at` touch was
cosmetic; the branch row's `updated_at` already tracks last-publish time for cleanup cutoffs.

The unconditional `branch.update(updated_at: now)` on every publish causes the same ShareLock
pattern on the `branches` row. Replaced with a conditional dataset UPDATE that only fires if
`updated_at` is older than 60 seconds — concurrent requests within the window skip the write,
with no impact on cleanup (which operates on day-level cutoffs).

---

## Error 2 — `versions` upsert tuple-lock deadlock

**Site:** `lib/pact_broker/versions/repository.rb` → `create_or_update` → `Version.new(...).upsert`

```
Process 12668 waits for ShareLock on transaction 18267088; blocked by process 12656.
Process 12656 waits for ShareLock on transaction 18267085; blocked by process 12670.
Process 12670 waits for AccessShareLock on tuple (125,10) of relation 'versions'; blocked by process 12668.
CONTEXT: while locking tuple (125,10) in relation 'versions'
```

Three concurrent publishes of the same consumer+version all race to `INSERT ... ON CONFLICT DO UPDATE`.
PostgreSQL's tuple-level locking for `ON CONFLICT DO UPDATE` creates a 3-way cycle.

### Fix

**`lib/pact_broker/versions/repository.rb` + `lib/pact_broker/domain/version.rb`**

Replace `upsert` with `insert_ignore` (`ON CONFLICT DO NOTHING`) followed by a separate
`UPDATE WHERE id = ?`. `DO NOTHING` releases without acquiring tuple locks on conflict; the
subsequent `UPDATE` queues on a safe row-level lock.

`version.rb` gets `plugin :insert_ignore` and a `return unless id` guard in `after_create`.
Without the guard, `OrderVersions.(self)` fires with `id=nil` on a conflict, calls `lock!`,
raises `Sequel::NoExistingObject`, which is then swallowed by `insert_ignore`'s rescue — 
exception-as-control-flow on every concurrent republish.

**Atomicity:** `branch_version_repository.rb` wraps `BranchVersion.insert_ignore` +
`BranchHead.upsert` in an inner transaction so both writes are atomic even in non-HTTP call
paths (test data builder, direct service calls) that lack the `DatabaseTransaction` middleware
outer transaction.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/pact_broker/domain/version.rb` | Add `plugin :insert_ignore`; guard `after_create` with `return unless id` |
| `lib/pact_broker/versions/repository.rb` | Replace `upsert` with `insert_ignore` + separate `update` in `create_or_update` |
| `lib/pact_broker/versions/branch_version_repository.rb` | Skip `branch_version.update` when row exists; conditional `branch.update`; add inner transaction |

---

## Verification

```bash
bundle exec rspec spec/lib/pact_broker/versions/ spec/lib/pact_broker/domain/version_spec.rb
```
