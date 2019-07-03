-- Deletes all verifications and pact publications that are older than 60 days,
-- and cleans up orphan pacticipant versions and their tags.
-- Also removes webhook execution history.

DELETE FROM verifications WHERE created_at < now() - '60 days'::interval;
DELETE FROM webhook_executions;
DELETE FROM triggered_webhooks;
DELETE FROM pact_publications WHERE created_at < now() - '60 days'::interval;
DELETE FROM pact_versions WHERE id NOT IN (SELECT distinct pact_version_id from pact_publications);
DELETE FROM tags WHERE version_id NOT IN (select consumer_version_id from pact_publications union select provider_version_id from verifications);
DELETE FROM versions WHERE id NOT IN (select consumer_version_id from pact_publications union select provider_version_id from verifications);
