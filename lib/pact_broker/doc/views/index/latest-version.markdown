# Latest pacticipant version

Allowed methods: `GET`

Given a pacticipant name, this resource returns the latest pacticipant version according to the configured ordering scheme. Ordering will be by creation date of the version resource if `order_versions_by_date` is true, and will be by semantic order if `order_versions_by_date` is false.

Note that this resource represents a pacticipant (application) version, not a pact version.
