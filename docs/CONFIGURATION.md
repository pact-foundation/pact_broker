# Pact Broker Configuration


<br/>

## Logging

<hr/>


### log_level

The application log level

**Required:** false<br/>
**Default:** `info`<br/>
**Allowed values:** `debug`, `info`, `warn`, `error`, `fatal`<br/>

### log_format

The application log format. Can be any value supported by Semantic Logger.

**Required:** false<br/>
**Default:** `default`<br/>
**Allowed values:** `default`, `json`, `color`<br/>
**More information:** https://github.com/rocketjob/semantic_logger/tree/master/lib/semantic_logger/formatters<br/>

### log_dir

The log file directory

**Required:** false<br/>
**Default:** `./logs`<br/>

### log_stream

The stream to which the logs will be sent. Set to `stdout` to stream to standard out.

**Required:** false<br/>
**Default:** `file`<br/>
**Allowed values:** `stdout`, `file`<br/>

<br/>

## Authentication and authorization

<hr/>
The Pact Broker comes with 2 configurable basic auth users - one with read/write privileges, and one with read only privileges.
The read only credentials should be distributed to the developers for use from development machines, and the read/write credentials
should be used for CI/CD.


### basic_auth_enabled

Whether to enabled basic authorization

**Required:** false<br/>
**Allowed values:** `true`, `false`<br/>

### basic_auth_username

The username for the read/write basic auth user

**Required:** false<br/>

### basic_auth_password

The password for the read/write basic auth user

**Required:** false<br/>

### basic_auth_read_only_username

The username for the read only basic auth user

**Required:** false<br/>

### basic_auth_read_only_password

The password for the read only basic auth user

**Required:** false<br/>

### allow_public_read

If you want to allow public read access, but still require credentials for writing, then leave `basic_auth_read_only_username` and `basic_auth_read_only_password` unset, and set `allow_public_read` to `true`

**Required:** false<br/>
**Allowed values:** `true`, `false`<br/>

### public_heartbeat

If you have enabled basic auth, but require unauthenticated access to the heartbeat URL (eg. for use within an AWS autoscaling group), set `public_heartbeat` to `true`

**Required:** false<br/>
**Allowed values:** `true`, `false`<br/>

<br/>

## TODO

<hr/>


### warning_error_class_names



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### hide_pactflow_messages



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### webhook_retry_schedule



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### webhook_http_method_whitelist



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### webhook_http_code_success



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### webhook_scheme_whitelist



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### webhook_host_whitelist



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### disable_ssl_verification



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### user_agent



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### port



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### base_url



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### base_urls



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### use_hal_browser



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### enable_diagnostic_endpoints



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### use_rack_protection



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### badge_provider_mode



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### enable_public_badge_access



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### shields_io_base_url



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### use_case_sensitive_resource_names



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### order_versions_by_date



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### base_equality_only_on_content_that_affects_verification_results



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### check_for_potential_duplicate_pacticipant_names



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### create_deployed_versions_for_tags



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### use_first_tag_as_branch



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### use_first_tag_as_branch_time_limit



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### semver_formats



**Required:** false<br/>
**Allowed values:** `todo`<br/>

### features



**Required:** false<br/>
**Allowed values:** `todo`<br/>

