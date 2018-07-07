# Latest pacticipant version with the specified tag

Allowed methods: `GET`

Given a pacticipant name and a pacticipant version tag name, this resource returns the latest pacticipant version with the specified tag. Note that the "latest" is determined by the creation date of the pacticipant version resource (or the semantic order if `order_versions_by_date` is false), not by the creation date of the tag.
