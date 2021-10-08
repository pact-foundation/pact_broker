# Pact Broker Configuration


<!-- This is a generated file. Please do not edit it directly. -->

The Pact Broker supports configuration via environment variables or a YAML file from version 2.87.0.1 of the Docker images.

To configure the application using a YAML file, place it in the location `config/pact_broker.yml`,
relative to the working directory of the application, or set the environment
variable `PACT_BROKER_CONF` to the full path to the configuration file.
<br/>

## Logging

<hr/>


### log_level

The application log level

**YAML configuration key name:** `log_level`<br/>
**Environment variable name:** `PACT_BROKER_LOG_LEVEL`<br/>
**Default:** `info`<br/>
**Allowed values:** `debug`, `info`, `warn`, `error`, `fatal`<br/>

### log_format

The application log format. Can be any value supported by Semantic Logger.

**YAML configuration key name:** `log_format`<br/>
**Environment variable name:** `PACT_BROKER_LOG_FORMAT`<br/>
**Default:** `default`<br/>
**Allowed values:** `default`, `json`, `color`<br/>
**More information:** https://github.com/rocketjob/semantic_logger/tree/master/lib/semantic_logger/formatters<br/>

### log_dir

The log file directory

**YAML configuration key name:** `log_dir`<br/>
**Environment variable name:** `PACT_BROKER_LOG_DIR`<br/>
**Default:** `./logs`<br/>

### log_stream

The stream to which the logs will be sent.

While the default is `file` for the Ruby application, it is set to `stdout` on the supported Docker images.

**YAML configuration key name:** `log_stream`<br/>
**Environment variable name:** `PACT_BROKER_LOG_STREAM`<br/>
**Default:** `file`<br/>
**Allowed values:** `stdout`, `file`<br/>

### hide_pactflow_messages

Set to `true` to hide the messages in the logs about Pactflow

**YAML configuration key name:** `hide_pactflow_messages`<br/>
**Environment variable name:** `PACT_BROKER_HIDE_PACTFLOW_MESSAGES`<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>
**More information:** https://pactflow.io<br/>

<br/>

## Database

<hr/>


### database_adapter

The database adapter. For production use, Postgres must be used.

For investigations/spikes on a development machine, you can use SQlite. It is not supported as a production database, as it does not support
concurrent requests.

**YAML configuration key name:** `database_adapter`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_ADAPTER`<br/>
**Default:** `postgres`<br/>
**Allowed values:** `postgres` (for production use), `sqlite` (for spikes only)<br/>

### database_username

The database username

**YAML configuration key name:** `database_username`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_USERNAME`<br/>

### database_password

The database password

**YAML configuration key name:** `database_password`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_PASSWORD`<br/>

### database_name

The database name. If using the `sqlite` adapter, this will be the path to the database file.

**YAML configuration key name:** `database_name`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_NAME`<br/>
**Examples:** `pact_broker`, `/tmp/pact_broker.sqlite3`, `./tmp/pact_broker.sqlite3`<br/>

### database_host

The database host

**YAML configuration key name:** `database_host`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_HOST`<br/>

### database_port

The database port. If ommited, the default port for the adapter will be used.

**YAML configuration key name:** `database_port`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_PORT`<br/>

### database_url

The full database URL may be specified instead of the separate adapter, username, password, name, host and port.

**YAML configuration key name:** `database_url`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_URL`<br/>
**Format:** `{database_adapter}://{database_username}:{database_password}@{database_host}:{database_port}/{database_name}`<br/>
**Examples:** `postgres://pact_broker_user:pact_broker_password@pact_broker_db_host/pact_broker`, `sqlite:///tmp/pact_broker.sqlite3` (relative path to working directory), `sqlite:////tmp/pact_broker.sqlite3` (absolute path)<br/>

### database_sslmode

The Postgresql ssl mode.

**YAML configuration key name:** `database_sslmode`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_SSLMODE`<br/>
**Default:** `prefer`<br/>
**Allowed values:** `disable`, `allow`, `prefer`, `require`, `verify-ca`, `verify-full`<br/>
**More information:** https://ankane.org/postgres-sslmode-explained<br/>

### sql_log_level

The log level that will be used when the SQL query statements are logged.

To disable noisy SQL query logging when the application `log_level` is set to `debug` for other reasons, use the value `none`.

**YAML configuration key name:** `sql_log_level`<br/>
**Environment variable name:** `PACT_BROKER_SQL_LOG_LEVEL`<br/>
**Default:** `debug`<br/>
**Allowed values:** `none`, `debug`, `info`, `warn`, `error`, `fatal`<br/>

### sql_log_warn_duration

The number of seconds after which to log an SQL query at warn level. Use this for detecting slow queries.

**YAML configuration key name:** `sql_log_warn_duration`<br/>
**Environment variable name:** `PACT_BROKER_SQL_LOG_WARN_DURATION`<br/>
**Default:** `5`<br/>
**Allowed values:** A positive integer or float, as a string.<br/>
**More information:** https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-General+connection+options<br/>

### database_max_connections

The maximum size of the connection pool (4 connections by default on most databases)

**YAML configuration key name:** `database_max_connections`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_MAX_CONNECTIONS`<br/>
**Default:** `4`<br/>
**Allowed values:** A positive integer value.<br/>
**More information:** https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-General+connection+options<br/>

### database_pool_timeout

The number of seconds to wait if a connection cannot be acquired before raising an error

**YAML configuration key name:** `database_pool_timeout`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_POOL_TIMEOUT`<br/>
**Default:** `5`<br/>
**Allowed values:** A positive integer.<br/>
**More information:** https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-General+connection+options<br/>

### database_connect_max_retries

When running the Pact Broker Docker image experimentally using Docker Compose on a local development machine,
the Broker application process may be ready before the database is available for connection, causing the application
container to exit with an error. Setting the max retries to a non-zero number will allow it to retry the connection the
configured number of times, waiting 3 seconds between attempts.

**YAML configuration key name:** `database_connect_max_retries`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_CONNECT_MAX_RETRIES`<br/>
**Default:** `0`<br/>
**Allowed values:** A positive integer value.<br/>

### auto_migrate_db

Whether or not to run the database schema migrations on start up. It is recommended to set this to `true`.

**YAML configuration key name:** `auto_migrate_db`<br/>
**Environment variable name:** `PACT_BROKER_AUTO_MIGRATE_DB`<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>

### auto_migrate_db_data

Whether or not to run the database data migrations on start up. It is recommended to set this to `true`.

**YAML configuration key name:** `auto_migrate_db_data`<br/>
**Environment variable name:** `PACT_BROKER_AUTO_MIGRATE_DB_DATA`<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>

### allow_missing_migration_files

If `true`, will not raise an error if a database migration is recorded in the database that does not have an
equivalent file in the codebase. If this is true, an older version of the code may be used with a newer version of the database,
however, data integrity issues may occur.

**YAML configuration key name:** `allow_missing_migration_files`<br/>
**Environment variable name:** `PACT_BROKER_ALLOW_MISSING_MIGRATION_FILES`<br/>
**Default:** `true`<br/>
**More information:** https://sequel.jeremyevans.net/rdoc/classes/Sequel/Migrator.html<br/>

### database_statement_timeout

The number of seconds after which an SQL query will be aborted. Only supported for Postgresql connections.

**YAML configuration key name:** `database_statement_timeout`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_STATEMENT_TIMEOUT`<br/>
**Default:** `15`<br/>
**Allowed values:** A positive integer or float.<br/>
**More information:** https://www.postgresql.org/docs/9.3/runtime-config-client.html<br/>

### metrics_sql_statement_timeout

The number of seconds after which the SQL queries used for the metrics endpoint will be aborted.
This is configurable separately from the standard `database_statement_timeout` as it may need to be significantly
longer than the desired value for standard queries.

**YAML configuration key name:** `metrics_sql_statement_timeout`<br/>
**Environment variable name:** `PACT_BROKER_METRICS_SQL_STATEMENT_TIMEOUT`<br/>
**Default:** `30`<br/>
**Allowed values:** A positive integer.<br/>

### database_connection_validation_timeout

The number of seconds after which to check the health of a connection from a connection pool before passing it to the application.

`-1` means that connections will be validated every time, which avoids errors
when databases are restarted and connections are killed.  This has a performance
penalty, so consider increasing this timeout if building a frequently accessed service.

**YAML configuration key name:** `database_connection_validation_timeout`<br/>
**Environment variable name:** `PACT_BROKER_DATABASE_CONNECTION_VALIDATION_TIMEOUT`<br/>
**Default:** -1 for v2.85.1 and earlier, 3600 for later versions.<br/>
**Allowed values:** -1 or any positive integer.<br/>
**More information:** https://sequel.jeremyevans.net/rdoc-plugins/files/lib/sequel/extensions/connection_validator_rb.html<br/>

<br/>

## Authentication and authorization

<hr/>
The Pact Broker comes with 2 configurable basic auth users - one with read/write privileges, and one with read only privileges.
The read only credentials should be distributed to the developers for use from development machines, and the read/write credentials
should be used for CI/CD.


### basic_auth_enabled

Whether to enable basic authorization. This is automatically set to true for the Docker images if the `basic_auth_username` and `basic_auth_password` are set.

**YAML configuration key name:** `basic_auth_enabled`<br/>
**Environment variable name:** `PACT_BROKER_BASIC_AUTH_ENABLED`<br/>
**Default:** `false`<br/>
**Allowed values:** `true`, `false`<br/>

### basic_auth_username

The username for the read/write basic auth user.

**YAML configuration key name:** `basic_auth_username`<br/>
**Environment variable name:** `PACT_BROKER_BASIC_AUTH_USERNAME`<br/>

### basic_auth_password

The password for the read/write basic auth user.

**YAML configuration key name:** `basic_auth_password`<br/>
**Environment variable name:** `PACT_BROKER_BASIC_AUTH_PASSWORD`<br/>

### basic_auth_read_only_username

The username for the read only basic auth user.

**YAML configuration key name:** `basic_auth_read_only_username`<br/>
**Environment variable name:** `PACT_BROKER_BASIC_AUTH_READ_ONLY_USERNAME`<br/>

### basic_auth_read_only_password

The password for the read only basic auth user.

**YAML configuration key name:** `basic_auth_read_only_password`<br/>
**Environment variable name:** `PACT_BROKER_BASIC_AUTH_READ_ONLY_PASSWORD`<br/>

### allow_public_read

If you want to allow public read access, but still require credentials for writing, then leave `basic_auth_read_only_username` and `basic_auth_read_only_password` unset, and set `allow_public_read` to `true`.

**YAML configuration key name:** `allow_public_read`<br/>
**Environment variable name:** `PACT_BROKER_ALLOW_PUBLIC_READ`<br/>
**Default:** `false`<br/>
**Allowed values:** `true`, `false`<br/>

### public_heartbeat

If you have enabled basic auth, but require unauthenticated access to the heartbeat URL (eg. for use within an AWS autoscaling group), set `public_heartbeat` to `true`.

**YAML configuration key name:** `public_heartbeat`<br/>
**Environment variable name:** `PACT_BROKER_PUBLIC_HEARTBEAT`<br/>
**Default:** `false`<br/>
**Allowed values:** `true`, `false`<br/>

### enable_public_badge_access

Set this to true to allow status badges to be embedded in README files without requiring a hardcoded password.

**YAML configuration key name:** `enable_public_badge_access`<br/>
**Environment variable name:** `PACT_BROKER_ENABLE_PUBLIC_BADGE_ACCESS`<br/>
**Default:** `false`<br/>
**Allowed values:** `true`, `false`<br/>

<br/>

## Webhooks

<hr/>


### webhook_retry_schedule

The schedule of seconds to wait between webhook execution attempts.
The default schedule is 10 sec, 1 min, 2 min, 5 min, 10 min, 20 min (38 minutes in total).

**YAML configuration key name:** `webhook_retry_schedule`<br/>
**Environment variable name:** `PACT_BROKER_WEBHOOK_RETRY_SCHEDULE`<br/>
**Format:** A space separated list of integers.<br/>
**Default:** `10 60 120 300 600 1200`<br/>

### webhook_http_method_whitelist

The allowed HTTP methods for webhooks.
It is highly recommended that only `POST` requests are allowed to ensure that webhooks cannot be used to retrieve sensitive information from hosts within the same network.

**YAML configuration key name:** `webhook_http_method_whitelist`<br/>
**Environment variable name:** `PACT_BROKER_WEBHOOK_HTTP_METHOD_WHITELIST`<br/>
**Format:** A space separated list.<br/>
**Default:** `POST`<br/>
**Allowed values:** `POST`, `GET` (not recommended), `PUT` (not recommended), `PATCH` (not recommended), `DELETE` (not recommended)<br/>

### webhook_http_code_success

If webhook call returns the response with an HTTP code that is listed in the success codes then the operation is
considered a success, otherwise the webhook will be re-triggered based on the `webhook_retry_schedule` configuration.

In most cases, configuring this is not necessary, but there are some CI systems that return a non 200 status for a success,
which is why this feature exists.

**YAML configuration key name:** `webhook_http_code_success`<br/>
**Environment variable name:** `PACT_BROKER_WEBHOOK_HTTP_CODE_SUCCESS`<br/>
**Format:** A space separated list of integers.<br/>
**Default:** `200 201 202 203 204 205 206`<br/>
**Allowed values:** `Any valid HTTP status code`<br/>

### webhook_scheme_whitelist

The allowed URL schemes for webhooks.

**YAML configuration key name:** `webhook_scheme_whitelist`<br/>
**Environment variable name:** `PACT_BROKER_WEBHOOK_SCHEME_WHITELIST`<br/>
**Format:** A space delimited list.<br/>
**Default:** `https`<br/>
**Allowed values:** `https`, `http`<br/>

### webhook_host_whitelist

A list of hosts, network ranges, or host regular expressions.
Regular expressions should start and end with a `/` to differentiate them from Strings.
Note that backslashes need to be escaped with a second backslash when setting via an environment variable.
Please read the [Webhook whitelists section](https://docs.pact.io/pact_broker/configuration/features#webhooks) of the Pact Broker configuration documentation to understand how the whitelist is used.

**YAML configuration key name:** `webhook_host_whitelist`<br/>
**Environment variable name:** `PACT_BROKER_WEBHOOK_HOST_WHITELIST`<br/>
**Examples:** `github.com`, `10.2.3.41/24`, `/.*\\.foo\\.com$/`<br/>
**More information:** https://docs.pact.io/pact_broker/configuration/#webhook-whitelists<br/>

### disable_ssl_verification

If set to true, SSL verification will be disabled for the HTTP requests made by the webhooks

**YAML configuration key name:** `disable_ssl_verification`<br/>
**Environment variable name:** `PACT_BROKER_DISABLE_SSL_VERIFICATION`<br/>
**Default:** `false`<br/>
**Allowed values:** `true`, `false`<br/>

### user_agent

The user agent to set when making HTTP requests for webhooks.

**YAML configuration key name:** `user_agent`<br/>
**Environment variable name:** `PACT_BROKER_USER_AGENT`<br/>
**Default:** `Pact Broker v{VERSION}`<br/>

<br/>

## Resources

<hr/>


### port

The HTTP port that the Pact Broker application will run on. This will only be honoured if you are deploying the Pact Broker using
a package that actually reads this property (eg. one of the supported Docker images). If you are running the vanilla Ruby application,
the application will run on the port the server has been configured to run on (eg. `bundle exec rackup -p 9393`)

**YAML configuration key name:** `port`<br/>
**Environment variable name:** `PACT_BROKER_PORT`<br/>
**Default:** `9292`<br/>

### base_url

The full URL (including port, if non-standard for the protocol) at which the application will be made available to users.
This is used to create the links in the API.
The application may run correctly without this attribute, however, it is strongly recommended to set it when
deploying the Pact Broker to production as it prevents cache poisoning security vulnerabilities.
It is also required when deploying the Broker behind a reverse proxy, and when the application has been mounted at a non-root context.
Note that this attribute does not change where the application is actually mounted (that is the concern of the deployment configuration) - it just changes the links.

**YAML configuration key name:** `base_url`<br/>
**Environment variable name:** `PACT_BROKER_BASE_URL`<br/>
**Examples:** `https://pact-broker.mycompany.com`, `https://my-company.com:9292/pact-broker`<br/>

### base_urls

An alias of base_url. From version 2.79.0, multiple base URLs can be configured for architectures that use
gateways or proxies that allow the same Pact Broker instance to be addressed with different base URLs.

**YAML configuration key name:** `base_urls`<br/>
**Environment variable name:** `PACT_BROKER_BASE_URLS`<br/>
**Format:** A space separated list.<br/>
**Example:** `http://my-internal-pact-broker:9292 https://my-external-pact-broker`<br/>

### shields_io_base_url

The URL of the shields.io server used to generate the README badges.

**YAML configuration key name:** `shields_io_base_url`<br/>
**Environment variable name:** `PACT_BROKER_SHIELDS_IO_BASE_URL`<br/>
**Default:** `https://img.shields.io`<br/>
**More information:** https://shields.io<br/>

### badge_provider_mode

The method by which the badges are generated. When set to `redirect`, a request to the Pact Broker for a badge will be sent a redirect response
to render the badge from the shields.io server directly in the browser. This is the recommended value.
When set to `proxy`, the Pact Broker will make a request directly to the configured shields.io server, and then send the returned file
back to the browser. This mode is not recommended for security and performance reasons.

**YAML configuration key name:** `badge_provider_mode`<br/>
**Environment variable name:** `PACT_BROKER_BADGE_PROVIDER_MODE`<br/>
**Default:** `redirect`<br/>
**Allowed values:** `redirect`, `proxy`<br/>

### enable_diagnostic_endpoints

Whether or not to enable the diagnostic endpoints at `/diagnostic/status/heartbeat` and `"diagnostic/status/dependencies`.
The heartbeat endpoint is for use by load balancers, and the dependencies endpoint is for checking that the database
is available (do not use this for load balancing, as it makes a database connection).

**YAML configuration key name:** `enable_diagnostic_endpoints`<br/>
**Environment variable name:** `PACT_BROKER_ENABLE_DIAGNOSTIC_ENDPOINTS`<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>

<br/>

## Domain

<hr/>


### check_for_potential_duplicate_pacticipant_names

When a pact is published, the consumer, provider and consumer version resources are automatically created.

To prevent a pacticipant (consumer or provider) being created multiple times with slightly different name variants
(eg. FooBar/foo-bar/foo bar/Foo Bar Service), a check is performed to determine if a new pacticipant name is likely to be a duplicate
of any existing applications. If it is deemed similar enough to an existing name, a 409 will be returned.

The response body will contain instructions indicating that the pacticipant name should be corrected if it was intended to be an existing one,
or that the pacticipant should be created manually if it was intended to be a new one.

To turn this feature off, set `check_for_potential_duplicate_pacticipant_names` to `false`, and make sure everyone is very careful with their naming!
The usefulness of the Broker depends on the integrity of the data, which in turn depends on the correctness of the pacticipant names.

**YAML configuration key name:** `check_for_potential_duplicate_pacticipant_names`<br/>
**Environment variable name:** `PACT_BROKER_CHECK_FOR_POTENTIAL_DUPLICATE_PACTICIPANT_NAMES`<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>

### create_deployed_versions_for_tags

When `create_deployed_versions_for_tags` is `true` and a tag is created, if there is an environment with the name of the newly created tag, a deployed version is
also created for the pacticipant version.

This is to assist in the migration from using tags to track deployments to using the deployed and released versions feature.

**YAML configuration key name:** `create_deployed_versions_for_tags`<br/>
**Environment variable name:** `PACT_BROKER_CREATE_DEPLOYED_VERSIONS_FOR_TAGS`<br/>
**Supported versions:** From v2.81.0<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>
**More information:** https://docs.pact.io/pact_broker/recording_deployments_and_releases/<br/>

### use_first_tag_as_branch

When `use_first_tag_as_branch` is `true`, the first tag applied to a version within the `use_first_tag_as_branch_time_limit` (10 seconds)
will be used to populate the `branch` property of the version.

This is to assist in the migration from using tags to track branches to using the branches feature.

**YAML configuration key name:** `use_first_tag_as_branch`<br/>
**Environment variable name:** `PACT_BROKER_USE_FIRST_TAG_AS_BRANCH`<br/>
**Supported versions:** From v2.82.0<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>

### auto_detect_main_branch

When `true` and a pacticipant version is created with a tag or a branch that matches one of the names in `main_branch_candidates`,
the `mainBranch` property is set for that pacticipant if it is not already set.

This is to assist in the migration from using tags to track branches to using the branches feature.

**YAML configuration key name:** `auto_detect_main_branch`<br/>
**Environment variable name:** `PACT_BROKER_AUTO_DETECT_MAIN_BRANCH`<br/>
**Supported versions:** From v2.82.0<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>

### main_branch_candidates

An array of potential main branch names used when automatically detecting the main branch for a pacticipant.

**YAML configuration key name:** `main_branch_candidates`<br/>
**Environment variable name:** `PACT_BROKER_MAIN_BRANCH_CANDIDATES`<br/>
**Supported versions:** From v2.82.0<br/>
**Format:** A space delimited list.<br/>
**Default:** `develop main master`<br/>

### allow_dangerous_contract_modification

Whether or not to allow the pact content for an existing consumer version to be modified. It is strongly recommended that this is set to false,
as allowing modification makes the results of can-i-deploy unreliable. When this is set to false as recommended, each commit must publish pacts
with a unique version number.

**YAML configuration key name:** `allow_dangerous_contract_modification`<br/>
**Environment variable name:** `PACT_BROKER_ALLOW_DANGEROUS_CONTRACT_MODIFICATION`<br/>
**Supported versions:** From v2.82.0<br/>
**Default:** For new installations of v2.82.0 and later, this defaults to `false`.<br/>
**Allowed values:** `true`, `false`<br/>
**More information:** https://docs.pact.io/versioning<br/>

<br/>

## Miscellaneous

<hr/>


### features

A list of features to enable in the Pact Broker for beta testing before public release.

**YAML configuration key name:** `features`<br/>
**Environment variable name:** `PACT_BROKER_FEATURES`<br/>
**Format:** A space separated list.<br/>

