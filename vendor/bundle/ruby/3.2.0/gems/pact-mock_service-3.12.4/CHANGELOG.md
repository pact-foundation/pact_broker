<a name="v3.12.4"></a>
### v3.12.4 (2026-01-06)

#### Bug Fixes

* remove unnecessary require	 ([7d5d375](/../../commit/7d5d375))

<a name="v3.12.3"></a>
### v3.12.3 (2024-06-17)

#### Bug Fixes

* rack 2.x dont load Rack::Handler::WEBrick class to avoid warnings	 ([c5e2311](/../../commit/c5e2311))

<a name="v3.12.2"></a>
### v3.12.2 (2024-06-15)

#### Bug Fixes

* Fix Rack 3 support	 ([f6b1869](/../../commit/f6b1869))
* Fix Rack > 3.0.0 support	 ([fab4a8f](/../../commit/fab4a8f))

<a name="v3.12.1"></a>
### v3.12.1 (2023-10-19)

#### Bug Fixes

* use .read instead of .string for reading stream from rack.input	 ([000e3fd](/../../commit/000e3fd))

<a name="v3.12.0"></a>
### v3.12.0 (2023-10-18)

#### Features

* add Rack 3 compatibility (#146)	 ([9afea51](/../../commit/9afea51))

<a name="v3.11.2"></a>
### v3.11.2 (2023-05-18)

#### Bug Fixes

* use native lockfile, rather than ruby gem, tested on ruby 3.3.0-dev	 ([9a51a01](/../../commit/9a51a01))

<a name="v3.11.1"></a>
### v3.11.1 (2023-05-05)

#### Bug Fixes

* set args via ** for diff_formatter.call	 ([96a00a9](/../../commit/96a00a9))

<a name="v3.11.0"></a>
### v3.11.0 (2022-08-17)

#### Features

* only print metrics warning once per thread	 ([1ae43da](/../../commit/1ae43da))

#### Bug Fixes

* fix ruby `circular require` warning (#136)	 ([615e59c](/../../commit/615e59c))

<a name="v3.10.0"></a>
### v3.10.0 (2022-02-21)

#### Features

* add telemetry	 ([db5dfa5](/../../commit/db5dfa5))

<a name="v3.9.1"></a>
### v3.9.1 (2021-06-03)

#### Bug Fixes

* check for nil body rather than falsey body when determining how to render mocked response Fixes: https://github.com/pact-foundation/pact-mock_service/issues/99	 ([d26e520](/../../commit/d26e520))

<a name="v3.9.0"></a>
### v3.9.0 (2021-05-17)

#### Features

* pass host into WEBrick options to allow configuration (#128)	 ([ec234a4](/../../commit/ec234a4))

<a name="v3.8.0"></a>
### v3.8.0 (2021-02-25)

#### Features

* include interaction diffs in verification response	 ([6306693](/../../commit/6306693))

<a name="v3.7.0"></a>
### v3.7.0 (2020-11-13)

#### Features

* use Pact::Query.parse_string to parse query string	 ([6cd0733](/../../commit/6cd0733))
* do not require files until command is executing	 ([ad54d0b](/../../commit/ad54d0b))

<a name="v3.6.2"></a>
### v3.6.2 (2020-08-10)

#### Bug Fixes

* update thor dependency (#124)	 ([54b3f85](/../../commit/54b3f85))

<a name="v3.6.1"></a>
### v3.6.1 (2020-04-22)


#### Bug Fixes

*  fix Ruby 2.7 kwargs warning (#122)	 ([4a46c21](/../../commit/4a46c21))


<a name="v3.6.0"></a>
### v3.6.0 (2020-03-14)


#### Features

* add 'Access-Control-Allow-Headers' = true to cors response headers (#121)	 ([61bd9d1](/../../commit/61bd9d1))


<a name="v3.5.0"></a>
### v3.5.0 (2020-01-17)


#### Features

* add token, username and password options to stub service (#118)	 ([76236d8](/../../commit/76236d8))


<a name="v3.3.1"></a>
### v3.3.1 (2020-01-16)


#### Bug Fixes

* put metadata on the correct decorator	 ([67ef5a6](/../../commit/67ef5a6))


<a name="v3.3.0"></a>
### v3.3.0 (2020-01-16)


#### Features

* log a warning when too many interactions are set on the mock service at once	 ([0ce6bef](/../../commit/0ce6bef))


<a name="v3.2.1"></a>
### v3.2.1 (2020-01-11)


#### Bug Fixes

* remove apparently unused require for thwait	 ([4a08fd5](/../../commit/4a08fd5))


<a name="v3.2.0"></a>
### v3.2.0 (2019-09-19)


#### Features

* **skip writing to pact**
  * Use writable_interactions when writing to pact file	 ([44ea0c3](/../../commit/44ea0c3))


<a name="v3.1.0"></a>
### v3.1.0 (2019-05-01)


#### Features

* pact-stub-service log level cli opt	 ([9264a87](/../../commit/9264a87))


<a name="v3.0.1"></a>
### v3.0.1 (2019-03-08)


#### Bug Fixes

* add missing host argument to server spawn	 ([ee5cf90](/../../commit/ee5cf90))


<a name="v3.0.0"></a>
### v3.0.0 (2019-02-21)


#### Features

* allow mock service host to be configured	 ([7e2d810](/../../commit/7e2d810))


<a name="v2.12.0"></a>
### v2.12.0 (2018-10-03)


#### Features

* only set 'Access-Control-Allow-Credentials' if required for preflight to succeed	 ([4ede738](/../../commit/4ede738))


<a name="v2.11.0"></a>
### v2.11.0 (2018-08-28)


#### Features

* **stub-server**
  * allow pacts to be loaded from a directory	 ([c5babe7](/../../commit/c5babe7))


<a name="v2.10.1"></a>
### v2.10.1 (2018-08-21)


#### Bug Fixes

* ensure specified value of --pact-specification-version is written in pact file	 ([bb93b0d](/../../commit/bb93b0d))


<a name="v2.10.0"></a>
### v2.10.0 (2018-08-07)


#### Features

* use Pact::Error subclass instead of RuntimeErrors	 ([a15dd3e](/../../commit/a15dd3e))


<a name="v2.9.8"></a>
### v2.9.8 (2018-07-23)


#### Bug Fixes

* require pact_specification_version when spawning mock service through app manager	 ([efdba96](/../../commit/efdba96))


<a name="v2.9.6"></a>
### v2.9.6 (2018-07-23)


#### Bug Fixes

* use dummy pact specification version for stub server	 ([3337f6d](/../../commit/3337f6d))
* pass the pact specification version from the control server to the mock server	 ([b585092](/../../commit/b585092))


<a name="v2.9.4"></a>
### v2.9.4 (2018-07-23)


#### Bug Fixes

* parse expected interactions with configured pact specification version	 ([1b960bf](/../../commit/1b960bf))


<a name="v2.9.3"></a>
### v2.9.3 (2018-07-13)


#### Bug Fixes

* set $stdout.sync = true	 ([f37c8f8](/../../commit/f37c8f8))


<a name="v2.9.2"></a>
### v2.9.2 (2018-07-12)


#### Bug Fixes

* send webrick startup and shutdown messages to stdout instead of stderr	 ([908089e](/../../commit/908089e))


<a name="v2.9.1"></a>
### v2.9.1 (2018-07-04)


#### Bug Fixes

* return Access-Control-Allow-Headers=* for OPTIONS requests with no Access-Control-Request-Headers	 ([855fd83](/../../commit/855fd83))


<a name="v2.9.0"></a>
### v2.9.0 (2018-06-15)


#### Features

* allow --log-level to be specified in the CLI	 ([cf84a34](/../../commit/cf84a34))


<a name="v2.8.1"></a>
### v2.8.1 (2018-06-01)


#### Bug Fixes

* revert bind webrick of consumer server to 0.0.0.0 f1e858e306cd45b72472dad0f213cc7657821adc	 ([f2ebb6a](/../../commit/f2ebb6a))


<a name="v2.7.1"></a>
### v2.7.1 (2018-05-09)


#### Bug Fixes

* ensure underscored headers are maintained	 ([0724701](/../../commit/0724701))


<a name="v2.7.0"></a>
### v2.7.0 (2018-05-04)


#### Features

* allow pact-stub-server to read pact from an http uri	 ([5cce3b2](/../../commit/5cce3b2))


<a name="v2.6.4"></a>
### v2.6.4 (2018-02-22)

#### Features

* allow output streams and consumer contract writer to be passed in to Pact::ConsumerContractWriter	 ([1856f21](/../../commit/1856f21))


#### Bug Fixes

* correctly handle reading locked pact file on windows	 ([2d14562](/../../commit/2d14562))


<a name="v2.6.3"></a>
### v2.6.3 (2017-12-18)

#### Bug Fixes

* **pact-stub-service**
  * ensure all interactions loaded when loading multiple pacts	 ([4c0d698](/../../commit/4c0d698))

<a name="v2.6.1"></a>
### 2.6.1 (2017-11-17)
* 141988f - fix: don't blow up if Access-Control-Request-Headers is not present in OPTIONS request (Beth Skurrie, Fri Nov 17 09:53:29 2017 +1100)

### 2.6.0 (2017-11-07)
* cad84fd - feat(monkeypatch): allow a monkeypatch file to be loaded before starting the mock service (Beth Skurrie, Tue Nov 7 13:30:05 2017 +1100)

### 2.5.4 (2017-10-30)
* 799b822 - fix: change rack-test to development dependency (Beth Skurrie, Mon Oct 30 10:05:11 2017 +1100)

### 2.5.3 (2017-10-30)
* 9ad0d10 - fix: read existing pact file before truncating it (Beth Skurrie, Mon Oct 30 09:43:42 2017 +1100)

### 2.5.2 (2017-10-30)
* 12f02b4 - fix: avoid corrupting pact file when writing to it (Beth Skurrie, Mon Oct 30 08:31:15 2017 +1100)

### 2.5.0 (2017-10-28)
* bc15e21 - feat(pact-stub-service): handle case where multiple responses match (Beth Skurrie, Sat Oct 28 09:15:55 2017 +1100)

### 2.4.0 (2017-10-13)
* 56bd683 - feat(stub): add pact-stub-service CLI (Beth Skurrie, Fri Oct 13 08:20:49 2017 +1100)

### 2.3.0 (2017-10-04)
* 79cbdc9 - feat: add example script showing usage (Beth Skurrie, Wed Oct 4 13:42:06 2017 +1100)
* 873d9ee - feat: only write pact on shutdown of mock service if pact has not already been written (Beth Skurrie, Wed Oct 4 13:41:01 2017 +1100)
* d3c6067 - feat(cli): add --pact-file-write-mode to cli and remove --unique-pact-file-names (Beth Skurrie, Wed Oct 4 08:01:25 2017 +1100)
* 476ae5c - feat: only include backtrace in error response for standard errors, not for pact::error (Beth Skurrie, Tue Oct 3 16:40:06 2017 +1100)
* a76dc7e - feat: add 'merge' pactfile_write_mode (Beth Skurrie, Tue Oct 3 10:13:36 2017 +1100)
* d0d82f2 - feat: use file locking to ensure pact file isn't corrupted when running multiple mock services in parallel (Beth Skurrie, Mon Oct 2 08:32:34 2017 +1100)

### 2.2.0 (2017-09-30)
* 3949e3d - feat(cli): add --unique-pact-file-names option (Beth Skurrie, Thu Sep 28 11:16:22 2017 +1000)

### 2.1.0 (12 May 2017)
* 5b89d95 - Updated location of pact specification version in pact to metadata.pactSpecification.version. As per issue #137 (Beth Skurrie, Fri May 12 11:03:54 2017 +1000)
* b85ad94 - Update mock service interaction decorator to use providerState between the consumer DSL and the mock service, just to avoid any further confusion! (Beth Skurrie, Fri May 12 08:41:56 2017 +1000)

### 2.0.1 (11 May 2017)
* 2c106b9 - Fix serialisation of request in pact for pact spec 2. (Beth Skurrie, Thu May 11 09:32:43 2017 +1000)

### 2.0.0 (12 Apr 2017)
* 74bd80e - Bumping pact-support version to ~> 1.0 (Beth Skurrie, Wed Apr 12 15:10:49 2017 +1000)

### 1.2.0 (4 Apr 2017)
* b2e9f46 - Updated pact-support gem dependency as an excuse to put out a new version so can rebuild pact-mock-service-npm. (Beth Skurrie, Tue Apr 4 15:56:12 2017 +1000)

### 1.1.0 (4 Apr 2017)
* dc5331b - Silence zip command in rake package task (Beth Skurrie, Tue Apr 4 10:29:10 2017 +1000)

### 1.0.0 (3 Apr 2017)
* 18b98c0 - Included request matching rules in pact file (Matt Baumgartner, Wed Feb 15 16:20:50 2017 -0500)

### 0.12.1 (11 Jan 2017)
* a0fbb02 - Upgrade Traveling Ruby to work on ruby 2.2.x (Matt Fellows, Tue Jan 10 22:57:32 2017 +1100)

### 0.12.0 (22 Nov 2016)
* 2fa1a58 - Skip SSL test on Travis for now (Bethany Skurrie, Tue Nov 22 10:26:41 2016 +1100)
* 22a7d1d - Attempting to cleanup failing test (Bobby Earl, Mon Oct 24 16:00:05 2016 -0400)
 * 43e779f - Added support for sslcert + sslkey to server.rb (Bobby Earl, Mon Oct 24 15:20:33 2016 -0400)
 * d1ab8ff - Added intergration test and updated README.md (Bobby Earl, Fri Oct 21 11:29:00 2016 -0400)
 * ae0a06c - Allow passing in an ssl certificate / key to use instead of having one generated. (Blackbaud-JonathanBell, Fri Oct 21 10:52:53 2016 -0400)

### 0.11.0 (14 Nov 2016)
* 8b32ea9 - Upgrading pact-support version (Beth Skurrie, Mon Nov 14 10:04:22 2016 +1100)

### 0.10.2 (13 Aug 2016)
* 9352017 - Update .travis.yml (Beth Skurrie, Mon Aug 8 18:06:41 2016 +1000)
* f719415 - use ssl when checking if https server is up (Valeriy Kassenbaev, Thu Aug 4 01:37:50 2016 +0300)

### 0.10.1 (27 Jun 2016)
* a9fff79 - Add release instructions (Sergei Matheson, Mon Jun 27 10:47:12 2016 +1000)
* 28c11e7 - Clarify that pact-mock_service will only work with ruby >= 2.0 (Sergei Matheson, Mon Jun 27 10:27:12 2016 +1000)

### 0.10.0 (10 June 2016)
* 9ebcd9e - Only write pact file when there are interactions (Robin Daugherty, Thu Jun 16 16:13:57 2016 -0400)

### 0.9.0 (26 May 2016)
* 28ab905 - Merge pull request #46 from reevoo/order_interactions_by_provider_state (Sergei Matheson, Thu May 26 14:52:08 2016 +1000)
* d58507c - Add ability to record interactions in alphabetical order. Order key: description + response.status + provider_state Default order: chronological (as it was before) (Alex Malkov, Mon May 23 11:52:39 2016 +0100)
* 739d111 - Merge pull request #48 from mefellows/readline-fix (Sergei Matheson, Mon May 16 10:53:01 2016 +1000)
* fe5ea69 - Added -rreadline flag to ruby CLI execution wrapper (Matt Fellows, Sun May 15 13:31:45 2016 +1000)
* 0dfb431 - Sort by description, status and provider state (Alex Malkov, Wed May 4 00:00:21 2016 +0100)
* 9ff8337 - Order interactions within the contract by provider state. (Alex Malkov, Tue May 3 22:13:53 2016 +0100)
* 2f22f7e - Update to ruby 2.3.1 in travis (Sergei Matheson, Tue May 3 10:46:46 2016 +1000)

### 0.8.2 (19 April 2016)
* e392333 - Merge pull request #45 from aaronrenner/ar-fix-almost-duplicate-error-web-response (Beth Skurrie, Tue Apr 19 09:53:01 2016 +1000)
* 6fbcce2 - Fixed invalid Rack response on AlmostDuplicateInteractionError (Aaron Renner, Mon Apr 18 14:08:19 2016 -0600)
* 2cdce52 - Merge pull request #44 from sebdiem/sebdiem/add_host_option (Sergei Matheson, Tue Mar 29 09:23:35 2016 +1100)
* a76a321 - add host option for control server (Sébastien Diemer, Sun Mar 27 23:25:19 2016 +0200)
* aadbb8d - Merge pull request #43 from taiki45/find-available-port-option (Sergei Matheson, Mon Mar 21 09:35:40 2016 +1100)
* 98c9233 - remove --pact-dir from the windows bat file #41 (Ron Holshausen, Fri Mar 18 11:42:22 2016 +1100)
* f4c2fa5 - Fix timing issue on server test (Taiki Ono, Thu Mar 17 17:24:22 2016 +0900)
* 0655161 - Format code (Taiki Ono, Thu Mar 17 00:19:45 2016 +0900)
* fbea6d4 - Support find_available_port option (Taiki Ono, Wed Mar 16 19:12:36 2016 +0900)
* e72b0cd - WEBrick expects port as Integer (Taiki Ono, Wed Feb 24 19:16:57 2016 +0900)
* 9580c41 - Merge pull request #42 from taiki45/update-travis-ci-setting (Sergei Matheson, Wed Mar 16 19:59:08 2016 +1100)
* 01b90e0 - Update Travis CI setting with new Rubies (Taiki Ono, Sun Mar 13 21:19:43 2016 +0900)


### 0.8.1 (25 February 2016)
* ffa37f8 - Merge pull request #40 from taiki45/add-option-not-to-write-pact-file (Beth Skurrie, Thu Feb 25 09:33:30 2016 +1100)
* 1cb2fa8 - Add option not to write pact file (Taiki Ono, Tue Feb 23 18:18:28 2016 +0900)
* 34b2b84 - Update README.md (Beth Skurrie, Tue Jan 19 14:17:21 2016 +1100)
* f8c92e4 - Update README.md (Beth Skurrie, Tue Jan 19 13:44:22 2016 +1100)
* 2012733 - Merge pull request #36 from Trunkplatform/cors_patch (Sergei Matheson, Wed Jan 13 14:16:29 2016 +1100)
* 8847938 - Added spec for PATCH method in the CORS allow methods (Sergei Matheson, Wed Jan 13 14:14:33 2016 +1100)
* 567714d - allowing PATCH method in the CORS handler (Evgeny Dudin, Tue Jan 12 12:20:52 2016 +1100)
* 56c7a51 - Update README.md (Beth Skurrie, Tue Jan 12 10:28:56 2016 +1100)
* 29380ed - Merge pull request #36 from davesmith00000/improved-usage-readme (Beth Skurrie, Tue Jan 12 10:22:04 2016 +1100)
* ef2da6c - Added a README example of using the pack-mock-server as a stub. (Dave Smith, Tue Jan 5 11:56:45 2016 +0000)

### 0.8.0 (30 November 2015)

* 96dc58b - Adds DELETE session endpoint (George Papas & Matt Fielding, Fri Nov 27 16:45:13 2015 +1100)

### 0.7.2 (7 October 2015)

* 24a092d - Updated pact-support gem (Beth Skurrie, Wed Oct 7 20:39:08 2015 +1100)

### 0.7.1 (27 August 2015)

* 5d1a150 - fixing wrapper to work with both symlinked and non-symlinked files, like when being used in node (Michel Boudreau, Thu Aug 27 12:06:38 2015 +1000)

### 0.7.0 (10 July 2015)

* 418b3a9 - Upgrading pact-support gem (Beth Skurrie, Fri Jul 10 13:11:13 2015 +1000)

### 0.6.0 (6 July 2015)

* fadbbd5 - Added a CLI option to alter binding address (Andrew Browne, Mon Jul 6 10:36:21 2015 +1000)

### 0.5.5 (25 May 2015)

* 3b2ec14 - Produce a valid rack response on interaction post error (David Heath, Fri May 22 16:42:03 2015 +0100)
* 9e3cb8b - Allow webrick_options to be passed in to Pact::MockService::Run to silence the start up and shut down logs if necessary (Beth Skurrie, Fri May 15 17:28:55 2015 +1000)

### 0.5.4 (13 May 2015)

* 7d016be - Fix failed merge which broke windows wrapper (Anthony Damtsis, Wed May 13 11:13:25 2015 +1000)

### 0.5.3 (12 May 2015)

* afef174 - Move non-windows ruby back to 2.1 to avoid version conflicts with windows (Anthony Damtsis, Tue May 12 16:12:31 2015 +1000)
* 22d10f8 - Default pact-dir for windows mock service included in wrapper. (Anthony Damtsis, Fri May 8 16:58:49 2015 +1000)

### 0.5.2 (23 Apr 2015)

* 718d1a6 - Fixing path (André Allavena, Thu Apr 23 12:55:26 2015 +1000)

### 0.5.1 (23 Mar 2015)

* 9b3127c - Fixing a path issue as %~dp0 resolves the path the bat is running from (Neil Campbell, Mon Mar 23 09:44:48 2015 +1100)
* 2199b0b - Added task to create win32 standalone package (Beth Skurrie, Fri Mar 20 16:32:04 2015 +1100)

### 0.5.0 (20 Mar 2015)

* ddc8c1a - Upgrade pact-support to ~>0.4.0 (Beth Skurrie, Fri Mar 20 14:53:00 2015 +1100)

### 0.4.2 (3 Mar 2015)

* 4c0e48b - Fixed bug where pact file was being cleared before being merged (Beth Skurrie, Tue Mar 3 17:27:02 2015 +1100)
* 661321a - Stop log/pact.log from being created automatically https://github.com/bethesque/pact-mock_service/issues/15 (Beth Skurrie, Tue Mar 3 08:45:15 2015 +1100)

### 0.4.1 (13 Feb 2015)

* 7be9338 - Fixed broken require that stopped restart working (Beth Skurrie, Wed Feb 25 13:55:32 2015 +1100)

### 0.4.0 (13 Feb 2015)

* 73ddd98 - Added option to AppManager to set the pact_specification_version (Beth Skurrie, Fri Feb 13 17:41:42 2015 +1100)
* e4a7405 - Make pactSpecificationVersion in pact file dynamic. (Beth Skurrie, Fri Feb 13 17:20:28 2015 +1100)
* ed9c550 - Create --pact-specification-version option to toggle between v1 and v2 serialization (Beth Skurrie, Fri Feb 13 16:56:30 2015 +1100)

### 0.3.0 (4 Feb 2015)

* 60869be - Refactor - moving classes from Pact::Consumer module into Pact::MockService module. (Beth Skurrie, Wed Feb 4 19:28:54 2015 +1100)
* 4ada4f0 - Added endpoint for PUT /interactions. Allow javascript client to set up all interactions at once and avoid callback hell. (Beth Skurrie, Thu Jan 29 21:48:00 2015 +1100)
* a329f49 - Add X-Pact-Mock-Service-Location header to all responses from the MockService (Beth Skurrie, Sun Jan 25 09:00:20 2015 +1100)

### 0.2.4 (24 Jan 2015)

* b14050e - Add --ssl option for control server (Beth, Sat Jan 24 22:14:14 2015 +1100)
* a9821fd - Add --cors option to control command (Beth, Sat Jan 24 21:51:40 2015 +1100)
* 16d62c8 - Added endpoint to check if server is up and running without causing an error (Beth, Thu Jan 8 14:33:26 2015 +1100)
* f93ff1f - Added restart for control and mock service (Beth, Thu Jan 8 14:02:19 2015 +1100)
* 54b2cb8 - Added control server to allow mock servers to be dynamically set up (Beth, Wed Jan 7 08:24:19 2015 +1100)

### 0.2.3 (21 Jan 2015)

* 560671e - Add support for using Pact::Terms in the path (Beth, Wed Jan 21 07:42:10 2015 +1100)
* 4324a97 - Renamed --cors-enabled to --cors (Beth, Wed Jan 21 07:28:34 2015 +1100)
* 5f5ee7e - Set Access-Control-Allow-Origin header to the the request Origin when populated. (Beth, Tue Jan 13 16:03:37 2015 +1100)

### 0.2.3.rc2 (13 Jan 2015)

* daf0696 - Added --consumer and --provider options to CLI. Automatically write pact if both options are given at startup. (Beth, Mon Jan 5 20:48:47 2015 +1100)
* 351c44e - Write pact on shutdown (Beth, Mon Jan 5 17:17:24 2015 +1100)
* e206c9f - Adding cross domain headers (André Allavena, Tue Dec 23 18:01:46 2014 +1000)

### 0.2.3.rc1 (3 Jan 2015)

* afd9cf3 - Removed awesome print gem dependency. (Beth, Sat Jan 3 16:49:40 2015 +1100)
* 5ae2c12 - Added rake task to package pact-mock-service as a standalone executable using Travelling Ruby. (Beth, Sat Jan 3 16:14:20 2015 +1100)
* b238f2a - Added message to indicate which part of the interactions differ when an interaction with the same description and provider state, but different request/response is added. https://github.com/realestate-com-au/pact/issues/18 (Beth, Sat Jan 3 14:20:36 2015 +1100)
* cf38365 - Moved check for 'almost duplicate' interaction to when the interaction is set up. If it occurs during replay, the error does not get shown to the user. https://github.com/bethesque/pact-mock_service/issues/1 (Beth, Sat Jan 3 11:10:47 2015 +1100)
* 1da9a74 - Added --pact-dir to CLI. Make --pact-dir and --log dir if they do not already exist. (Beth, Sat Jan 3 09:07:03 2015 +1100)
* 4a2a9a2 - Added handler for SIGTERM to shut down mock service. (Beth, Fri Jan 2 12:07:29 2015 +1100)
* 57c1a14 - Added support to run the mock service on SSL. Important for browser-based consumers. (Tal Rotbart, Wed Dec 31 09:43:52 2014 +1100)

### 0.2.2 (29 October 2014)

* 515ed14 - Added feature tests for mock service to show how it should respond under different circumstances. (Beth, Wed Oct 29 09:21:15 2014 +1100)
* de6f670 - Added missing require for interaction decorator. (Beth, Wed Oct 29 09:19:27 2014 +1100)

### 0.2.1 (24 October 2014)

* a4cf177 - Reifying the request headers, query and body when serializing pact. This allows Pact::Term to be used in the request without breaking verification for non-ruby providers that can't deserialise the Ruby specific serialisation of Pact::Terms. (Beth, Fri Oct 24 15:27:18 2014 +1100)

### 0.2.0 (24 October 2014)

* d071e2c - Added field to /pact request body to specify the pact directory (Beth, Fri Oct 24 09:22:06 2014 +1100)

### 0.1.0 (22 October 2014)

* 62caf8e - Removed Gemfile.lock from git (bethesque, Wed Oct 22 13:07:54 2014 +1100)
* 5b4d54e - Moved JSON serialisation code into decorators. Serialisation between DSL and mock service is different from serialisation to the pact file. (bethesque, Wed Oct 22 13:07:00 2014 +1100)
