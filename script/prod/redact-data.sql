UPDATE pacticipants SET name = 'pacticipant-' || id;
UPDATE versions SET number = 'version-' || id;
UPDATE pact_versions SET content = '{}';
UPDATE verifications SET test_results = null;
DELETE FROM webhook_executions;
DELETE FROM triggered_webhooks;
DELETE FROM webhooks;
DELETE FROM certificates;

UPDATE tags
SET name = temprow.redacted_name
FROM
  ( SELECT name, 'tag-' || ROW_NUMBER () OVER (ORDER BY name) as redacted_name FROM (
    SELECT DISTINCT name FROM tags WHERE lower(name) NOT IN ('master', 'test', 'dev', 'prod', 'production') ORDER BY name
  ) as x) as temprow
WHERE tags.name = temprow.name;
