Do this to generate your change history

    $ git log --date=relative --pretty=format:'  * %h - %s (%an, %ad)' 'package/pact-broker-0.0.PRODVERSION'..'package/pact-broker-0.0.NEWVERSION'

#### 0.0.5 (2013-11-13)

* 2cf987c - Added data migration to script which adds order column (Beth, 56 minutes ago)
* 9c709a9 - Changing queries to use new order column. (Beth, 61 minutes ago)
* 173f231 - Renaming var (Beth, 65 minutes ago)
* f9be93d - Renamed SortVersions to OrderVersions (Beth, 66 minutes ago)
* ca6e479 - Added SortVersions as an after version save hook (Beth, 69 minutes ago)
* 23cd1a3 - Adding order column to version table (Beth, 11 hours ago)
* c504e5f - Fixing application/json+hal to application/hal+json (Beth, 2 days ago)
* 1d24b9b - Removing old sinatra API (Beth, 2 days ago)
* fd1832c - WIP. Converting to use Webmachine (Beth, 2 days ago)
* 0b096a4 - Redoing the the URLs yet again (Beth, 3 days ago)
* 0934d89 - Implementing list latest pacts (Beth, 3 days ago)
* ed2d354 - Changed one_to_one associations to many_to_one (Beth, 4 days ago)
* 28de0ea - WIP implementing pacts/latest. (Beth, 6 days ago)
* 1cd36e6 - Changing to new /pacts/latest URL format (Beth, 6 days ago)
* 54f8fc3 - Writing underlying code to find the latest pact for each consumer/provider pair. (Beth, 6 days ago)
