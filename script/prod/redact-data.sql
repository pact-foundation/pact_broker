update pacticipants set name = 'pacticipant-' || id;
update pact_versions set content = '{}';
update verifications set test_results = null;
delete from webhook_executions;
delete from triggered_webhooks;
delete from webhooks;
delete from certificates;
