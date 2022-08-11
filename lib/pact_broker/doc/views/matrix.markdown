# Matrix

Allowed methods: `GET`

This resource returns the "cartesian join" of every pact publication and every verification results publication, and is used to determine whether or not a set of integrated application versions are safe to deploy together.

If you need to use this API, consider calling the `/can-i-deploy` resource instead, as it provides an interface that is easier to understand.

## Matrix selectors and options

Selectors are the way we specify which pacticipants and versions we want to view the matrix for. The best way to understand them is to imagine that we start with a Matrix table that contains the pacts/verification results for every consumer and provider in the Pact Broker.

| Consumer | Consumer version | Provider | Provider version | Success |
|----------|------------------|----------|------------------|---------|
| Foo      | 1                | Oink     | 6                | true    |
| Foo      | 1                | Bar      | 2                | true    |
| Foo      | 1                | Bar      | 3                | false   |

To specify that we wanted to see all the rows between Foo and Bar, our selectors would be:

`{"pacticipant": "Foo"}` and `{"pacticipant": "Bar"}`.

This would return:

| Consumer | Consumer version | Provider | Provider version | Success |
|----------|------------------|----------|------------------|---------|
| Foo      | 1                | Bar      | 2                | true    |
| Foo      | 1                | Bar      | 3                | false   |

To specify that we wanted to see the results for Foo v1 and Bar v3, our selectors would be:

`{"pacticipant": "Foo", "version": "1"}` and `{"pacticipant": "Bar", "version": "3"}`.

This would return:

| Consumer | Consumer version | Provider | Provider version | Success |
|----------|------------------|----------|------------------|---------|
| Foo      | 1                | Bar      | 3                | false   |


Best "Pact Broker" practice specifies that once a pact is published for a particular consumer version, it should not be overwritten, however, there is nothing built in to the broker to stop multiple pacts being published with the same consumer version. If the provider verifies each revision, we would end up with a table that looks like this:

| Consumer | Consumer version | Provider | Provider version | Success |
|----------|------------------|----------|------------------|---------|
| Foo      | 1 (revision 1)   | Bar      | 3                | false   |
| Foo      | 1 (revision 2)   | Bar      | 3                | true    |
| Foo      | 1 (revision 3)   | Bar      | 3                | false   |

The overwritten revisions are not useful for determining whether or not we are safe to deploy, so to remove these lines from the dataset, we can specify the option `{latestby: "cvpv"}` to return the latest row when grouped and ordered by "consumer version and provider version".

Putting the selectors and the options together, to specify that we wanted to see the *latest* results for Foo v1 and Bar v3, our selectors would be:

`{"pacticipant": "Foo", "version": "1"}` and `{"pacticipant": "Bar", "version": "3"}` and our options would be `{"latestby": "cvpv"}`.

This would return:

| Consumer | Consumer version | Provider | Provider version | Success |
|----------|------------------|----------|------------------|---------|
| Foo      | 1 (revision 3)   | Bar      | 3                | false   |


Instead of specifying the version using the version number, you can also specify it by indicating the tag name.

| Consumer | Consumer version | Provider | Provider version | Success |
|----------|------------------|----------|------------------|---------|
| Foo      | 1 (prod)         | Bar      | 2                | true    |
| Foo      | 1 (prod)         | Bar      | 3 (prod)         | true    |
| Foo      | 2                | Bar      | 4 (prod)         | true    |
| Foo      | 2                | Bar      | 5                | true    |

Version 1 of Foo has been tagged prod, while versions 3 and 4 of Bar have been tagged prod.

To determine if Foo v2 can be deployed with the latest prod version of Bar, our selectors would be:

`{"pacticipant": "Foo", "version": "2"}` and `{"pacticipant": "Bar", tag: "prod", latest: true}` and our options would be `{"latestby": "cvpv"}`.

Using the dataset above, this query would return:

| Consumer | Consumer version | Provider | Provider version | Success |
|----------|------------------|----------|------------------|---------|
| Foo      | 2                | Bar      | 4 (prod)         | true    |


Imagine that Foo added another provider (and may add more in the future). It would be brittle to specify each of its integration partners by name. The Pact Broker already knows which applications Foo integrates with, so let's allow it to work out the dependencies by itself.

To determine if Foo v2 can be deployed with the latest prod versions of all its integration partners, our selectors would be:

`{"pacticipant": "Foo", "version": "2"}` and our options would be `{ "tag": "prod", latest: true, latestby: "cvp"}`. (Note the change in `latestby` from "cvpv" to "cvp". The reasons why this is the case are beyond the scope of this document.)


If Foo was a mobile client, and Bar was its provider, we might want to know if a particular version of Bar was compatible with _all_ the production versions of Foo. To do this, we drop the `"latest": true` from Foo's selector, like so: `{"pacticipant": "Foo", "tag": "prod"}` and `{"pacticipant": "Bar", version: "3"}`. Using the dataset from above, this query would return the following rows:

| Consumer | Consumer version | Provider | Provider version | Success |
|----------|------------------|----------|------------------|---------|
| Foo      | 1 (prod)         | Bar      | 2                | true    |
| Foo      | 1 (prod)         | Bar      | 3 (prod)         | true    |
