# Pacticipant branch

Allowed methods: `GET`, `DELETE`

Path: `/pacticipants/{pacticipant}/branches/{branch}`

Get or delete a pacticipant branch.

## Create

Branches cannot be created via the resource URL. They are created automatically when publishing contracts.

## Get

### Example

    curl http://broker/pacticipants/Bar/branches/main -H "Accept: application/hal+json"

## Delete

Deletes a pacticipant branch. Does NOT delete the associated pacticipant versions.

Send a `DELETE` request to the branch resource.

    curl -XDELETE http://broker/pacticipants/Bar/branches/main
