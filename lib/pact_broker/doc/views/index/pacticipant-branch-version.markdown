# Pacticipant branch version

Allowed methods: `GET`, `PUT`

Path: `/pacticipants/{pacticipant}/branches/{branch}/versions/{version}`

Get or add/create a pacticipant version for a branch.

## Example

Add a version to a branch. The pacticipant and branch are automatically created if they do not exist.

    curl -XPUT http://broker/pacticipants/Bar/branches/main/versions/1e70030c6579915e5ff56b107a0fd25cf5df7464 \
          -H "Content-Type: application/json" -d ""
