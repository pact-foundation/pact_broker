# Pagination

Pagination of results is available for some endpoints used by Pact. These paginated responses can be used to programmatically load smaller subsections of the api results, in turn enabling improved performance and easier client side management of the data.

  For endpoints that support pagination a paginated response can be retrieved using the following query parameters:

pageNumber=1

pageSize=100

```
https://pact-broker/pacticipants?pageSize=1&pageNumber=1
```

Including one or both of these in the api call will result in a paginated response. Where only one parameter is included the other will use the default value.

    To retrieve the next or previous page of the paginated response use the URL provided in the response body under the `_links` section, labeled `next` or `previous`.
    The first page will not have a previous link, while the last page will not have a next link.
      Note any page can be retrieved by updating the pageNumber parameter.

        ```
    "_links": {
        "next": {
          "href": "http://pact-broker/pacticipants?pageSize=1&pageNumber=2",
          "title": "Next page"
        },

        ```

## Paginated endpoints

The following endpoints in Pact support pagination via the above query parameters:

### [Pacticipants](https://docs.pact.io/pact_broker/api/pacticipants)
Ordered Alphabetically by the Pacticipant name.
### [Pacticipant Versions](https://docs.pact.io/pact_broker/overview#pacticipant-versions)
Ordered by date in reverse (most recent Pacticipant Version will be first).