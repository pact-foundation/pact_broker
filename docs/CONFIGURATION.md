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

### hide_pactflow_messages

Set to `true` to hide the messages in the logs about Pactflow

**Required:** false<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>
**More information:** https://pactflow.io<br/>

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

### enable_public_badge_access

Set this to true to allow status badges to be embedded in README files without requiring a hardcoded password

**Required:** false<br/>
**Allowed values:** `true`, `false`<br/>

<br/>

## Webhooks

<hr/>


### webhook_retry_schedule

The schedule of seconds to wait between webhook execution attempts.
The default schedule is 10 sec, 1 min, 2 min, 5 min, 10 min, 20 min (38 minutes in total)

**Required:** false<br/>
**Format:** A space separated list of integers.<br/>
**Default:** `10 60 120 300 600 1200`<br/>

### webhook_http_method_whitelist

The allowed HTTP methods for webhooks.
It is highly recommended that only `POST` requests are allowed to ensure that webhooks cannot be used to retrieve sensitive information from hosts within the same network.

**Required:** false<br/>
**Format:** A space separated list.<br/>
**Default:** `POST`<br/>
**Allowed values:** `POST`, `GET (not recommended)`, `PUT (not recommended)`, `PATCH (not recommended)`, `DELETE (not recommended)`<br/>

### webhook_http_code_success

If webhook call returns the response with an HTTP code that is listed in the success codes then the operation is
considered a success, otherwise the webhook will be re-triggered based on the `webhook_retry_schedule` configuration.

In most cases, configuring this is not necessary, but there are some CI systems that return a non 200 status for a success,
which is why this feature exists.

**Required:** false<br/>
**Format:** A space separated list of integers.<br/>
**Default:** `200 201 202 203 204 205 206`<br/>
**Allowed values:** `any valid HTTP status code`<br/>

### webhook_scheme_whitelist

The allowed URL schemes for webhooks.

**Required:** false<br/>
**Format:** A space delimited list.<br/>
**Default:** `https`<br/>
**Allowed values:** `https`, `http`<br/>

### webhook_host_whitelist

A list of hosts, network ranges, or host regular expressions.
Regular expressions should start and end with a `/` to differentiate them from Strings.
Note that backslashes need to be escaped with a second backslash when setting via an environment variable.
Please read the Webhook whitelists section of the Pact Broker configuration documentation to understand how the whitelist is used.

**Required:** false<br/>
**Examples:** `github.com`, `10.2.3.41/24`, `/.*\\.foo\\.com$/`<br/>
**More information:** https://docs.pact.io/pact_broker/configuration/#webhook-whitelists<br/>

### disable_ssl_verification

If set to true, SSL verification will be disabled for the HTTP requests made by the webhooks

**Required:** false<br/>
**Allowed values:** `true`, `false`<br/>

<br/>

## HTTP

<hr/>


### port

The HTTP port that the Pact Broker application will run on. This will only be honoured if you are deploying the Pact Broker using
a package that actually reads from this property (eg. one of the Docker images). If you are running the vanilla Ruby application,
the application will run on the port the server has been configured to run on (eg. `bundle exec rackup -p 9393`)

**Required:** false<br/>
**Default:** `9292`<br/>

### base_url

The full URL (including port, if non-standard for the protocol) at which the application will be made available to users.
This is used to create the links in the API.
The application may run correctly without this attribute, however, it is strongly recommended to set it when
deploying the Pact Broker to production as it prevents cache poisoning security vulnerabilities.
It is also required when deploying the Broker behind a reverse proxy, and when the application has been mounted at a non-root context.
Note that this attribute does not change where the application is actually mounted (that is the concern of the deployment configuration) - it just changes the links.

**Required:** false<br/>
**Examples:** `https://pact-broker.mycompany.com`, `https://my-company.com:9292/pact-broker`<br/>

### base_urls

An alias of base_url. From version 2.79.0, multiple base URLs can be configured for architectures that use
gateways or proxies that allow the same Pact Broker instance to be addressed with different base URLs.

**Required:** false<br/>
**Format:** A space separated list.<br/>
**Example:** `http://my-internal-pact-broker:9292 https://my-external-pact-broker`<br/>

### shields_io_base_url

The URL of the shields.io server used to generate the README badges.

**Required:** false<br/>
**Default:** `https://img.shields.io`<br/>
**More information:** https://shields.io<br/>

### check_for_potential_duplicate_pacticipant_names

When a pact is published, the consumer, provider and consumer version resources are automatically created.

To prevent a pacticipant (consumer or provider) being created multiple times with slightly different name variants
(eg. FooBar/foo-bar/foo bar/Foo Bar Service), a check is performed to determine if a new pacticipant name is likely to be a duplicate
of any existing applications. If it is deemed similar enough to an existing name, a 409 will be returned.

The response body will contain instructions indicating that the pacticipant name should be corrected if it was intended to be an existing one,
or that the pacticipant should be created manually if it was intended to be a new one.

To turn this feature off, set `check_for_potential_duplicate_pacticipant_names` to `false`, and make sure everyone is very careful with their naming!
The usefulness of the Broker depends on the integrity of the data, which in turn depends on the correctness of the pacticipant names.

**Required:** false<br/>
**Default:** `true`<br/>
**Allowed values:** `true`, `false`<br/>

### create_deployed_versions_for_tags

To assist in migrating from tags to deployed 

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

