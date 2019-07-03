-- Deletes all verifications and pact publications that are older than 60 days,
-- and cleans up orphan pacticipant versions and their tags.
-- Also removes webhook execution history.

DELETE FROM verifications WHERE created_at < now() - '60 days'::interval;
DELETE FROM webhook_executions;
DELETE FROM triggered_webhooks;
DELETE FROM pact_publications WHERE created_at < now() - '60 days'::interval;
DELETE FROM pact_versions WHERE id NOT IN (SELECT DISTINCT pact_version_id FROM pact_publications);
DELETE FROM tags WHERE version_id NOT IN (SELECT consumer_version_id FROM pact_publications UNION SELECT provider_version_id FROM verifications);
DELETE FROM versions WHERE id NOT IN (SELECT consumer_version_id FROM pact_publications UNION SELECT provider_version_id FROM verifications);
