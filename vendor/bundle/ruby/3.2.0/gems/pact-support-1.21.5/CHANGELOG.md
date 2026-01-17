<a name="v1.21.5"></a>
### v1.21.5 (2026-01-09)

#### Bug Fixes

* **deps**
  * explictly add logger & irb/fiddle - dev for fake fs for ruby 4.0.0 support	 ([b5d906e](/../../commit/b5d906e))

<a name="v1.21.4"></a>
### v1.21.4 (2025-10-03)

#### Bug Fixes

* **deps**
  * Replace awesome_print with amazing_print #122 (#123)	 ([e894445](/../../commit/e894445))

* **spec**
  * workaround for diff formatted errors in ruby 3.4	 ([5627237](/../../commit/5627237))

* json load diff regression downstream	 ([1ed2ce7](/../../commit/1ed2ce7))

<a name="v1.21.3"></a>
### v1.21.3 (2025-06-26)

#### Bug Fixes

* use the safe json load to fix deprecation warnings.	 ([5d12ac6](/../../commit/5d12ac6))

<a name="v1.21.2"></a>
### v1.21.2 (2024-12-04)

#### Bug Fixes

* prevent insertion of extra new lines in JSON	 ([50189f2](/../../commit/50189f2))

<a name="v1.21.1"></a>
### v1.21.1 (2024-11-29)

#### Bug Fixes

* add blank lines to empty hashs - json 2.8.x regression for pact-ruby	 ([f8cb384](/../../commit/f8cb384))

<a name="v1.21.0"></a>
### v1.21.0 (2024-11-28)

#### Features

* add like_integer / like_decimal helpers	 ([75a36cd](/../../commit/75a36cd))
* add v3/v4 generators (thanks @slt)	 ([fe04975](/../../commit/fe04975))

#### Bug Fixes

* add blank lines to empty hashs - json 2.8.x regression	 ([66910bd](/../../commit/66910bd))

<a name="v1.20.2"></a>
### v1.20.2 (2024-10-23)

#### Bug Fixes

* **test**
  * explicitly require ostruct as non stdlib in ruby 3.5.x	 ([e06a057](/../../commit/e06a057))

* use single quotes for pact term creation err msg	 ([d770791](/../../commit/d770791))

<a name="v1.20.1"></a>
### v1.20.1 (2024-08-08)

#### Bug Fixes

* enable color on non-tty if color_enabled	 ([0585424](/../../commit/0585424))

<a name="v1.20.0"></a>
### v1.20.0 (2023-10-19)

#### Features

* handle x509 certs in HTTP Client (#99)	 ([6a36a48](/../../commit/6a36a48))

<a name="v1.19.0"></a>
### v1.19.0 (2022-11-15)

#### Features

* **generators**
  * add generators to a consumer contract request (#97)	 ([fbce4cb](/../../commit/fbce4cb))

<a name="v1.18.1"></a>
### v1.18.1 (2022-08-17)

#### Bug Fixes

* use send to invoke remove_method when removing as_json from Regexp	 ([cb29cdd](/../../commit/cb29cdd))

<a name="v1.18.0"></a>
### v1.18.0 (2022-03-28)

#### Features

* replace term-ansicolor with rainbow	 ([e8b6ada](/../../commit/e8b6ada))

#### Bug Fixes

* Fixup ruby warnings (#96)	 ([cee7113](/../../commit/cee7113))

<a name="v1.17.0"></a>
### v1.17.0 (2021-10-01)

#### Features

* allow SSL verification to be disabled by setting environment variable PACT_DISABLE_SSL_VERIFICATION=true	 ([dd39c04](/../../commit/dd39c04))

<a name="v1.16.10"></a>
### v1.16.10 (2021-10-01)

#### Bug Fixes

* change expgen to a runtime dependency	 ([da81634](/../../commit/da81634))

<a name="v1.16.9"></a>
### v1.16.9 (2021-09-30)

#### Bug Fixes

* remove randexp dependency (#91)	 ([794fd4e](/../../commit/794fd4e))

<a name="v1.16.8"></a>
### v1.16.8 (2021-07-27)

#### Bug Fixes

* log HTTP request for pacts retrieved by URL when requested with verbose=true	 ([3288b81](/../../commit/3288b81))

<a name="v1.16.7"></a>
### v1.16.7 (2021-01-28)

#### Bug Fixes

* dynamically parse actual query to match expected format	 ([a86a3e3](/../../commit/a86a3e3))

<a name="v1.16.6"></a>
### v1.16.6 (2021-01-28)

#### Bug Fixes

* raise Pact::Error not RuntimeError when invalid constructor arguments are supplied to a Pact::Term	 ([d9fb8ea](/../../commit/d9fb8ea))
* update active support support for Ruby 3.0	 ([6c30d42](/../../commit/6c30d42))

<a name="v1.16.5"></a>
### v1.16.5 (2020-11-25)

#### Bug Fixes

* maintain the original string query for the provider verification while also parsing the string query into a hash to allow the matching rules to be applied correctly for use in the mock service on the consumer side	 ([12105dd](/../../commit/12105dd))

<a name="v1.16.4"></a>
### v1.16.4 (2020-11-13)

#### Bug Fixes

* ensure expected and actual query strings are parsed consistently	 ([4e9ca9c](/../../commit/4e9ca9c))

<a name="v1.16.3"></a>
### v1.16.3 (2020-11-10)

#### Bug Fixes

* add missing params_hash_has_key	 ([700efa7](/../../commit/700efa7))

<a name="v1.16.2"></a>
### v1.16.2 (2020-11-07)

#### Bug Fixes

* removed undefined depth from query	 ([53a373d](/../../commit/53a373d))

<a name="v1.16.1"></a>
### v1.16.1 (2020-11-06)

#### Bug Fixes

* add missing params_hash_type? from Rack	 ([3195b0a](/../../commit/3195b0a))

<a name="v1.16.0"></a>
### v1.16.0 (2020-11-04)

#### Features

* remove runtime dependency on rspec	 ([aca30e2](/../../commit/aca30e2))

<a name="v1.15.5"></a>
### v1.15.5 (2020-11-04)

#### Bug Fixes

* add missing outputs to release workflow	 ([d565d0f](/../../commit/d565d0f))
* try different output syntax	 ([b11e8fb](/../../commit/b11e8fb))

<a name="v1.15.4"></a>
### v1.15.4 (2020-11-04)

#### Bug Fixes

* update release gem action version	 ([9dead58](/../../commit/9dead58))

<a name="v1.15.3"></a>
### v1.15.3 (2020-11-04)


#### Bug Fixes

* release workflow	 ([4bdf8d8](/../../commit/4bdf8d8))
* not actually a fix, just triggering new release	 ([74038a5](/../../commit/74038a5))


<a name="v1.15.2"></a>
### v1.15.2 (2020-11-04)


#### Bug Fixes

* parse query string to hash for v2 interactions	 ([faff17c](/../../commit/faff17c))


<a name="v1.15.0"></a>
### v1.15.0 (2020-04-30)


#### Bug Fixes

* follow first redirect when fetching remote pact artifacts. (#80)	 ([c1df6dd](/../../commit/c1df6dd))


<a name="v1.14.3"></a>
### v1.14.3 (2020-04-06)


#### Bug Fixes

* do not blow up when there are no matchers	 ([ac70846](/../../commit/ac70846))


<a name="v1.14.2"></a>
### v1.14.2 (2020-03-25)


#### Bug Fixes

* don't blow up when there is a term inside an each like	 ([a565a56](/../../commit/a565a56))


<a name="v1.14.1"></a>
### v1.14.1 (2020-02-27)


#### Bug Fixes

* correctly parse matching rules for request paths	 ([cc15a72](/../../commit/cc15a72))


<a name="v1.14.0"></a>
### v1.14.0 (2020-02-13)


#### Features

* use certificates from SSL_CERT_FILE and SSL_CERT_DIR environment variables in HTTP connections	 ([bf1333d](/../../commit/bf1333d))


<a name="v1.13.0"></a>
### v1.13.0 (2020-01-24)


#### Features

* give each interaction an index when parsing the contract	 ([74e9568](/../../commit/74e9568))


<a name="v1.12.1"></a>
### v1.12.1 (2020-01-22)


#### Bug Fixes

* add missing require for pact/configuration	 ([bc4bbb5](/../../commit/bc4bbb5))


<a name="v1.12.0"></a>
### v1.12.0 (2019-09-26)


#### Features

* parse interaction _id from Pact Broker	 ([8d66a84](/../../commit/8d66a84))
* support marking an interaction as writable/not writable (#75)	 ([e1fc347](/../../commit/e1fc347))
* modernise gemspec	 ([c941d02](/../../commit/c941d02))


#### Bug Fixes

* add CHANGELOG to gem distribution	 ([35c9c48](/../../commit/35c9c48))


<a name="v1.11.0"></a>
### v1.11.0 (2019-06-18)


#### Features

* allow Integers and Floats to be considered equivalent when using type based matching.	 ([d8a70a1](/../../commit/d8a70a1))


<a name="v1.10.3"></a>
### v1.10.3 (2019-06-07)


#### Bug Fixes

* gracefully handle diff between an expected multipart form request and an actual application/json request	 ([8577d52](/../../commit/8577d52))


<a name="v1.10.2"></a>
### v1.10.2 (2019-05-20)


#### Bug Fixes

* allow proxy env var to be used when fetching pacts	 ([ebce481](/../../commit/ebce481))


<a name="v1.10.1"></a>
### v1.10.1 (2019-04-26)


#### Bug Fixes

* gracefully handle read only file system (eg RunKit)	 ([eeee528](/../../commit/eeee528))


<a name="v1.10.0"></a>
### v1.10.0 (2019-03-15)


#### Bug Fixes

* don't try and fix producer keys for a nil string	 ([94245c7](/../../commit/94245c7))


<a name="v1.9.0"></a>
### v1.9.0 (2019-02-22)


#### Features

* allow bearer token to be used to retrieve a pact	 ([ab997c5](/../../commit/ab997c5))


<a name="v1.8.1"></a>
### v1.8.1 (2018-11-15)


#### Bug Fixes

* correctly handle ignored 'combine' rule	 ([cd52108](/../../commit/cd52108))


<a name="v1.8.0"></a>
### v1.8.0 (2018-10-01)


#### Features

* **v3**
  * parse array of provider states with params	 ([4471df3](/../../commit/4471df3))


<a name="v1.7.2"></a>
### v1.7.2 (2018-08-09)


#### Bug Fixes

* correctly handle Pact.like and Pact.each_like at top level of body	 ([f37c283](/../../commit/f37c283))


<a name="v1.7.1"></a>
### v1.7.1 (2018-08-09)


#### Bug Fixes

* remove incorrect warning messages about matching rules being ignored	 ([30328e0](/../../commit/30328e0))


<a name="v1.7.0"></a>
### v1.7.0 (2018-08-07)


#### Features

* add support for multipart/form	 ([8ed4332](/../../commit/8ed4332))


<a name="v1.6.6"></a>
### v1.6.6 (2018-07-25)


#### Bug Fixes

* correctly handle an 'each like' inside a 'like'	 ([7dc76dc](/../../commit/7dc76dc))


<a name="v1.6.5"></a>
### v1.6.5 (2018-07-23)


#### Features

* use 0 as the nil pact specification version	 ([88e4750](/../../commit/88e4750))
* reify StringWithMatchingRules to a String	 ([a025dd3](/../../commit/a025dd3))
* parse String response and request bodies to StringWithMatchingRules to support pact-xml	 ([a9fbb58](/../../commit/a9fbb58))
* add custom contract parsers to front of pact parsers list so that customised parsers are tried first	 ([babc319](/../../commit/babc319))


#### Bug Fixes

* show a more helpful error when attempting to parse a URI that is not a pact	 ([a8ba1ed](/../../commit/a8ba1ed))


<a name="v1.6.4"></a>
### v1.6.4 (2018-07-14)


#### Bug Fixes

* correctly serialize query params that use a Pact.each_like in pact file	 ([b3414dd](/../../commit/b3414dd))


<a name="v1.6.3"></a>
### v1.6.3 (2018-07-12)


#### Bug Fixes

* remove incorrect warning about ignoring unsupported matching rules for min => x	 ([50d5f6d](/../../commit/50d5f6d))
* serialize ArrayLike in query params without wrapping another array around it	 ([b4a9ec7](/../../commit/b4a9ec7))


<a name="v1.6.2"></a>
### v1.6.2 (2018-05-31)


#### Bug Fixes

* **windows-path**
  * prevent locale file paths to be parsed by URI to stop errors in windows paths like spaces in paths	 ([ecf64d6](/../../commit/ecf64d6))


<a name="v1.6.1"></a>
### v1.6.1 (2018-05-21)


#### Bug Fixes

* correctly read local windows pact file paths with backslashes	 ([e27bd38](/../../commit/e27bd38))


<a name="v1.6.0"></a>
### v1.6.0 (2018-04-03)


#### Features

* add support for writing v3 matching rules	 ([fc89696](/../../commit/fc89696))


<a name="v1.5.2"></a>
### v1.5.2 (2018-03-23)

#### Bug Fixes

* remove include of pact matchers in query string	 ([c478dff](/../../commit/c478dff))


<a name="v1.5.1"></a>
### v1.5.1 (2018-03-23)

#### Bug Fixes

* add missing require for pact matchers in query	 ([927d3b9](/../../commit/927d3b9))


<a name="v1.5.0"></a>
### v1.5.0 (2018-03-23)

#### Features

* parse pacts without a specification version as v2	 ([a69b5e6](/../../commit/a69b5e6))
* locate matching rules correctly for v3 pacts	 ([0f22db2](/../../commit/0f22db2))
* read matching rules from v3 format	 ([07013de](/../../commit/07013de))
* allow different consumer contract parsers to be registered	 ([531ab3a](/../../commit/531ab3a))
* update message classes to support pact-message	 ([2e48892](/../../commit/2e48892))
* add request and response to message	 ([93839cf](/../../commit/93839cf))

* **message contracts**
  * dynamically mix in new and from_hash into Pact::Message	 ([c0c3ad5](/../../commit/c0c3ad5))
  * read message pact into Ruby object	 ([6573bd4](/../../commit/6573bd4))


<a name="v1.3.1"></a>
### v1.3.1 (2018-03-19)

#### Bug Fixes

* dynamically load pact/matchers	 ([d80e0ff](/../../commit/d80e0ff))


<a name="v1.3.0"></a>
### v1.3.0 (2018-03-19)

#### Features

* do not automatically create tmp/pacts dir	 ([de9e25e](/../../commit/de9e25e))


<a name="v1.2.5"></a>
### v1.2.5 (2018-02-16)

#### Bug Fixes

* replace backslashes in pact dir path with forward slashes	 ([a1b5013](/../../commit/a1b5013))

### 1.2.4 (2017-10-30)
* 80bbdcc - fix: remove unused dependency on rack-test (Beth Skurrie, Mon Oct 30 09:52:22 2017 +1100)

### 1.2.3 (2017-10-30)
* 68be738 - fix: diff message when actual 'array like' is too long (Beth Skurrie, Mon Oct 30 09:28:20 2017 +1100)

### 1.2.2 (2017-10-27)
* 97ba7d9 - fix: correctly handle array like when key not found (Beth Skurrie, Fri Oct 27 12:50:50 2017 +1100)

### 1.2.1 (2017-10-03)
* c3b3f22 - fix: ignore invalid params in response constructor hash (Beth Skurrie, Tue Oct 3 15:40:22 2017 +1100)

### 1.2.0 (2017-09-28)
* 4489d96 - feat(pact file name): allow unique pact file names to be generated (Beth Skurrie, Thu Sep 28 11:05:33 2017 +1000)

### 1.1.8 (2017-09-25)
* d4029ab - fix: use reified value when creating diff message for arrays (Beth Skurrie, Fri Sep 22 10:57:01 2017 +1000)

### 1.1.7 (2017-09-15)
* a339b52 - Gemspec: Try using FakeFS 0.11.2 (Olle Jonsson, Wed Sep 13 09:28:27 2017 +0200)

### 1.1.6 (2017-08-25)
* be9ef39 - fix(matching): use single quotes instead of double to escape keys with dots (Beth Skurrie, Fri Aug 25 09:41:14 2017 +1000)

### 1.1.5 (1 Aug 2017)
* 81bc967 - fix(match type rules): Allow match: 'type' to be specified on the parent element of the array. Closes: #35, https://github.com/pact-foundation/pact-provider-verifier/issues/8 (Beth Skurrie, Tue Aug 1 10:33:02 2017 +1000)

### 1.1.4 (31 July 2017)
* 425881c - fix(cirular dependency for UnixDiffFormatter): Fixes circular dependency between pact/configuration and pact/matchers/unix_diff_formatter (Beth Skurrie, Mon Jul 31 11:45:44 2017 +1000)

### 1.1.3 (28 July 2017)
* cd0fc09 - fix(pact serialisation): Use square bracket notation for JSON path keys containing dots when serialising the pact Fixes https://github.com/pact-foundation/pact-support/issues/39 (Beth Skurrie, Fri Jul 28 09:39:15 2017 +1000)

### 1.1.2 (20 June 2017)
* 8c3e53d - Fixing recursive require problems for https://github.com/pact-foundation/pact-support/issues/36 (Beth Skurrie, Tue Jun 20 18:59:24 2017 +1000)

### 1.1.1 (20 June 2017)
* 14789df - Adding missing requires for #36 (Beth Skurrie, Tue Jun 20 16:27:43 2017 +1000)

### 1.1.0 (19 June 2017)
* 1659c54 - Add list of messages to diff output (Beth Skurrie, Mon Jun 19 09:39:08 2017 +1000)
* e18debc - Reify actual and expected when a type difference is encountered while doing exact matching (Beth Skurrie, Tue May 30 09:24:18 2017 +1000)
* 2ba49b6 - Updating matching rules extraction to use inheritance as per #34 (Beth Skurrie, Mon May 29 16:17:57 2017 +1000)

### 1.0.1 (11 May 2017)
* e34374b - Extract rules for QueryHash and QueryString so we can include request matching rules in the pact. (Beth Skurrie, Thu May 11 09:11:19 2017 +1000)

### 1.0.0 (12 Apr 2017)
* 0ad2ef5 - Stop removing trailing slash from path, as per https://github.com/pact-foundation/pact-specification/blob/version-2/testcases/request/path/missing%20trailing%20slash%20in%20path.json (Beth Skurrie, Wed Apr 12 14:59:04 2017 +1000)
* 7f93c00 - add a helper to match a non iso861 datetime string (Courtney Braafhart, Thu Apr 6 12:18:53 2017 -0500)

### 0.6.1 (10 Mar 2017)
* 4627b56 - Explicit require of CGI class. (Tan Le, Thu Mar 9 17:01:37 2017 +1100)
* 26b6678 - Added colon support to matching rules path. (soundstep, Wed Mar 8 09:18:35 2017 +0000)

### 0.6.0 (14 Nov 2016)
* 64a9a37 - Enable interactions to validate themselves (Taiki Ono, Wed Nov 9 19:08:49 2016 +0900)

### 0.5.9 (27 Jun 2016)
* dea4645 - Clarify that pact-support will only work with ruby >= 2.0 (Sergei Matheson, Mon Jun 27 10:18:32 2016 +1000)
* 50ea21f - Update json_differ.rb (Beth Skurrie, Thu Jun 9 16:01:34 2016 +1000)
* d303870 - Comment. (Beth Skurrie, Thu Jun 9 15:57:34 2016 +1000)

### 0.5.8 (26 May 2016)
* 768b382 - Add pactfile_write_order configuration (Alex Malkov, Mon May 23 11:02:27 2016 +0100)

### 0.5.7 (3 May 2016)
* 289d4e5 - Handle loading local pact files as well as remote (Sergei Matheson, Tue May 3 12:56:51 2016 +1000)
* 6d4e559 - Update to ruby 2.3.1 in travis (Sergei Matheson, Tue May 3 10:46:46 2016 +1000)

### 0.5.6 (29 April 2016)
* d8bc8fa - Remove pull request merge logs from changelog (Sergei Matheson, Fri Apr 29 10:06:51 2016 +1000)
* 24ba197 - Corrected v0.5.5 release date in CHANGELOG (Sergei Matheson, Fri Apr 29 10:05:11 2016 +1000)
* 9dcef8d - Retry reading pact file (Taiki Ono, Thu Apr 28 17:15:54 2016 +0900)
* 61ceda1 - Re-write test with WebMock (Taiki Ono, Thu Apr 28 15:50:29 2016 +0900)
* 62dcf66 - Use WebMock2 (Taiki Ono, Thu Apr 28 13:51:53 2016 +0900)

### 0.5.5 (29 April 2016)
* eb9aa26 - Supporting nested Pact::SomethingLike reification (Takatoshi Maeda, Thu Apr 28 02:04:58 2016 +0900)
* 9e924c8 - Object supporting DSL can be built without block (Taiki Ono, Wed Mar 23 16:38:27 2016 +0900)
* 2b0e7b4 - Escape query string components (Taiki Ono, Mon Mar 14 15:22:29 2016 +0900)
* a383368 - Fix indent (Taiki Ono, Mon Mar 14 15:18:26 2016 +0900)
* dc54092 - Support latest jruby and drop supporting jruby 1.7 (Taiki Ono, Sun Mar 13 20:27:17 2016 +0900)
* 85fbb09 - Drop supporting ruby1.9 (Taiki Ono, Thu Mar 10 23:01:54 2016 +0900)
* 966fa3a - `raise_error` should be with specific error (Taiki Ono, Thu Mar 10 22:50:13 2016 +0900)
* 2861742 - Cosmetic change (Taiki Ono, Thu Mar 10 22:11:51 2016 +0900)
* c491682 - `QueryHash` accepts nested hash query (Taiki Ono, Thu Mar 10 21:24:41 2016 +0900)

### 0.5.4 (4 November 2015)

* 2791b72 - [+AM] Add like_datetime_with_milisecods helper method (David Sevcik, Wed Nov 4 17:40:53 2015 +0100)

### 0.5.3 (8 September 2015)

* c7b1454 - Apply reification to ArrayLike flexible matcher. (Matt Fellows, Tue Sep 8 11:35:32 2015 +1000)

### 0.5.2 (13 August 2015)

* cb88842 - Add shortcuts like_uuid, like_datetime, like_date (Alex Malkov, Thu Aug 13 09:34:23 2015 +0100)

### 0.5.1 (19 July 2015)

* bd24aff - Remove rspec require from pact/support.rb to stop rspec's let method overriding minitest's let method (Beth Skurrie, Sun Jul 19 07:49:15 2015 +1000)
* bbe9553 - Support bracket notation in matching rule jsonpaths. (Beth Skurrie, Fri Jul 10 15:16:55 2015 +1000)

### 0.5.0 (10 July 2015)

* 9451bf4 - Created helper methods for Pact::Term, SomethingLike and ArrayLike (Beth Skurrie, Fri Jul 10 11:44:45 2015 +1000)

### 0.4.4 (9 July 2015)

* 6d9be6e - Create no rules for exact matching (Beth Skurrie, Thu Jul 9 14:28:56 2015 +1000)

### 0.4.3 (7 July 2015)

* cf99e97 - Handle nils when symbolizing keys in a hash (Beth Skurrie, Tue Jul 7 11:52:50 2015 +1000)
* b100ccd - Log warning when no content type is found that text diff will be performed on body (Beth Skurrie, Sun May 10 21:57:07 2015 +1000)

### 0.4.2 (9 May 2015)

* 75f98d7 - Added missing requires (Beth Skurrie, Sat May 9 16:20:07 2015 +1000)

### 0.4.1 (23 April 2015)

* 7da52f3 - Switch from require_relative to require to avoid double-loading when symlinks are involved (John Meredith, Thu Apr 23 14:46:03 2015 +1000)

### 0.4.0 (20 March 2015)

* 409bde5 - support url including basic authentication info, e.g.: http://username:password@packtbroker.com (lifei zhou, Wed Mar 18 21:49:29 2015 +1100)
* d0d42bb - added http basic authentication options when open uri (lifei zhou, Thu Feb 26 22:03:21 2015 +1100)

### 0.3.1 (24 Februrary 2015)

* e3d6d6d - Fixed bug when Content-Type is a Pact::Term. (Beth Skurrie, Tue Feb 24 17:25:10 2015 +1100)

### 0.3.0 (13 Februrary 2015)

* 4e29277 - Create a public API for extracting matching rules for pact-mock_service to use. (Beth Skurrie, Fri Feb 13 15:35:14 2015 +1100)
* 17ffb7e - Improve Pact::Term error message when value does not match regexp. (Beth Skurrie, Thu Feb 12 15:35:28 2015 +1100)
* ad0b37b - Added logic to convert Term and SomethingLike to v2 matching rules (Beth Skurrie, Thu Feb 12 14:55:34 2015 +1100)
* cc15c4d - Renamed <index not found> to <item not found>, and <index not to exist> to <item not to exist> (Beth Skurrie, Thu Feb 12 11:47:53 2015 +1100)
* 1b65c46 - Change "no difference here" to ... in unix diff output (Beth Skurrie, Thu Feb 12 11:43:58 2015 +1100)
* 3cb5b30 - Fix duplicate "no difference here!" in diff when actual array has more items than the expected (Beth Skurrie, Thu Feb 12 11:30:58 2015 +1100)
* a9da567 - Changed display of NoDiffAtIndex (Beth Skurrie, Tue Dec 23 15:16:49 2014 +1100)
* f9619e6 - Log warning message when unsupported rules are detected (Beth Skurrie, Tue Dec 23 14:42:22 2014 +1100)
* 9875bef - Added support for v2 regular expression matching in provider (Beth Skurrie, Tue Dec 23 14:15:00 2014 +1100)

### 0.2.1 (21 January 2015)

* 4e26c75 - Ignore HTTP method case when determining if routes match. https://github.com/bethesque/pact-support/issues/3 (Beth, Tue Jan 20 20:15:20 2015 +1100)
* af96eba - Allow request path to be a Pact::Term (Beth, Tue Jan 20 19:37:23 2015 +1100)

### 0.1.4 (20 January 2015)

A naughty release because bumping the minor version to 0.2.0 means I have to upgrade all the gems.

### 0.2.0 (20 January 2015)

* bb5d893 - Added option to UnixDiffFormatter to not show the explanation (Beth, Tue Jan 20 08:39:42 2015 +1100)

### 0.1.3 (12 December 2014)

* 27f3625 - Fixed bug rendering no diff indicator as JSON (Beth, Fri Dec 12 10:42:50 2014 +1100)

### 0.1.2 (22 October 2014)

* 00280ac - Added logic to match form data when specified as a Hash (bethesque, Wed Oct 22 15:21:39 2014 +1100)

### 0.1.1 (22 October 2014)

* ff6a01d - Disallowing unexpected params in the query (bethesque, Wed Oct 22 14:42:41 2014 +1100)

### 0.1.0 (22 October 2014)

* fa7e03f - Removed JSON serialisation code from models. It has been moved to decorators in pact_mock-service. (bethesque, Wed Oct 22 12:53:21 2014 +1100)

### 0.0.4 (20 October 2014)

* ebe5e32 - Added differ for application/x-www-form-urlencoded bodies. (bethesque, Mon Oct 20 20:26:13 2014 +1100)

### 0.0.3 (17 October 2014)

* bab0b34 - Added possibility to provide queries as Hash. Then order of parameters in the query is not longer relevant. (André Allavena, Tue Oct 14 00:24:38 2014 +1000)

### 0.0.2 (12 October 2014)

* e7080fe - Added a QueryString class in preparation for a QueryHash class (Beth, Sun Oct 12 14:32:15 2014 +1100)
* 8839151 - Added Travis config (Beth, Sun Oct 12 12:31:44 2014 +1100)
* 81ade54 - Removed CLI (Beth, Sun Oct 12 12:29:22 2014 +1100)
* 3bdde98 - Removing unused files (Beth, Sun Oct 12 12:11:48 2014 +1100)
* ef95717 - Made it build (Beth, Sat Oct 11 13:24:35 2014 +1100)
* 1e78b62 - Removed pact-test.rake (Beth, Sat Oct 11 13:20:49 2014 +1100)
* 3389b5e - Initial commit (Beth, Sat Oct 11 13:13:23 2014 +1100)
