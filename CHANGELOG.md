Do this to generate your change history

    $ git log --pretty=format:'  * %h - %s (%an, %ad)'

#### 0.0.10 (2014-06-06)

  * 24daeea - Added task to delete pacticipant (bethesque Tue May 20 11:59:10 2014 +1000)
  * 53e24cb - Increased json_content size from text to mediumtext (16MB) (bethesque Mon May 19 15:43:32 2014 +1000)
  * 73e2b81 - Implemented finding latest pact by tag (bethesque Sat May 17 17:56:58 2014 +1000)
  * bfa62cc - Changed /pact to /pacts because it is more RESTy (bethesque Sat May 17 12:22:55 2014 +1000)
  * a7a8e0d - Upgraded padrino (bethesque Sat May 17 12:20:57 2014 +1000)
  * 94c7c38 - Setting gem versions in gemspec (bethesque Fri May 9 15:22:37 2014 +1000)
  * f497f13 - Made HtmlPactRenderer configurable in case shokkenki want to use the PactBroker ;) (bethesque Fri May 9 14:20:38 2014 +1000)
  * 1d35da4 - Added sort to relationships list (bethesque Fri May 9 13:56:55 2014 +1000)
  * 000f8a6 - Added HAL Browser link (bethesque Fri May 9 13:39:56 2014 +1000)
  * 85e0a1d - Redirecting index to relationships page (bethesque Fri May 9 13:15:55 2014 +1000)
  * 5343019 - Added Relationship UI (bethesque Fri May 9 12:23:30 2014 +1000)
  * f7270a6 - Added HTML rendering of latest pact. (bethesque Thu May 8 16:17:52 2014 +1000)

#### 0.0.10 (2014-03-24)

* 7aee2ae - Implemented version tagging (bethesque 2 days ago)
* cc78f92 - Added 'latest' pact url to pact representation in the 'latest pacts' response (bethesque 2 days ago)

#### 0.0.9 (2014-02-27)

* d07f4b7 - Using default gem publish tasks (bethesque 4 weeks ago)
* d60b7ee - Comment (bethesque 7 weeks ago)
* 836347c - Using local pacts (bethesque 7 weeks ago)
* a2cb2bb - Fixed bug querying mysql DB, rather than sqlite (bethesque 7 weeks ago)
* 9d5f83b - Using the to_json options to pass in the base_url instead of the nasty hack. (bethesque 4 months ago)
* adb6148 - Changed 'last' to 'latest' (bethesque 4 months ago)

#### 0.0.8 (2013-11-18)

* 6022baa - Changed name to title in list pacticipants response (bethesque 7 hours ago)
* 13fde52 - Moving resources module under the Api module. (bethesque 8 hours ago)
* f52c572 - Added HAL index (bethesque 8 hours ago)

#### 0.0.7 (2013-11-15)

* 7984d86 - Added title to each item in the pacts/latest links array (bethesque 83 seconds ago)

#### 0.0.6 (2013-11-15)

* 021faae - Refactoring resources to DRY out code (bethesque 18 hours ago)
* bab0367 - Cleaning up the base_url setting hack. (bethesque 19 hours ago)
* f6df613 - Renamed representors to decorators (bethesque 19 hours ago)
* 3e89c20 - Created BaseDecorator (bethesque 19 hours ago)
* e5c3f88 - Changing from representors to decorators (bethesque 19 hours ago)
* b2eeb6f - Added back resource_exists? implementation in pacticipant resource - accidental deletion. (bethesque 19 hours ago)
* 1962a05 - Ever so slightly less hacky way of handling PATCH (bethesque 21 hours ago)
* 587e9c1 - First go at trying to use a dynamic base URL - to be continued (bethesque 2 days ago)
* ab9c185 - Including URLs for the dynamically calculated latest pact, not the hard link to the latest pact. (bethesque 2 days ago)
* 5621e41 - Beginning change from Roar Representor to Decoractor. Updating to new 'latest pact' URL (bethesque 2 days ago)
* d1bd995 - Adding missing PactBroker::Logging require (bethesque 2 days ago)


#### 0.0.5 (2013-11-13)

* 2cf987c - Added data migration to script which adds order column (bethesque 56 minutes ago)
* 9c709a9 - Changing queries to use new order column. (bethesque 61 minutes ago)
* 173f231 - Renaming var (bethesque 65 minutes ago)
* f9be93d - Renamed SortVersions to OrderVersions (bethesque 66 minutes ago)
* ca6e479 - Added SortVersions as an after version save hook (bethesque 69 minutes ago)
* 23cd1a3 - Adding order column to version table (bethesque 11 hours ago)
* c504e5f - Fixing application/json+hal to application/hal+json (bethesque 2 days ago)
* 1d24b9b - Removing old sinatra API (bethesque 2 days ago)
* fd1832c - WIP. Converting to use Webmachine (bethesque 2 days ago)
* 0b096a4 - Redoing the the URLs yet again (bethesque 3 days ago)
* 0934d89 - Implementing list latest pacts (bethesque 3 days ago)
* ed2d354 - Changed one_to_one associations to many_to_one (bethesque 4 days ago)
* 28de0ea - WIP implementing pacts/latest. (bethesque 6 days ago)
* 1cd36e6 - Changing to new /pacts/latest URL format (bethesque 6 days ago)
* 54f8fc3 - Writing underlying code to find the latest pact for each consumer/provider pair. (bethesque 6 days ago)
