# Pacticipant version tag

Allowed methods: `GET`, `PUT`, `DELETE`

Path: `/pacticipants/{pacticipant}/versions/{version}/tags/{tag}`

To create a tag, send an empty request with the URL specified above and `Content-Type` of `application/json`.

Tags must be applied before pacts or verification results are published to ensure that the webhook fires with the correct metadata.
