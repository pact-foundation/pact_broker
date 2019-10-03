# Can I Deploy

Allowed methods: `GET`

A simplified resource that accepts the same parameters as the basic usage of the `can-i-deploy` CLI command.

**Parameters**:

* _pacticipant_: The name of the pacticipant (application) you want to deploy (required).
* _version_: The version of the pacticipant (application) you want to deploy (required).
* _to_: The tag used to identify the environment into which you wish to deploy the application (eg. `test` or `prod`). This assumes you have already tagged the currently deployed versions of each of the integrated applications with the same tag. To be specific, the logic checks if the application version you have specified is compatible with the latest versions _for the specified tag_ of all the other applications it is integrated with. This parameter is optional - if not specified, it checks for compatiblity with the latest version of all the integrated applications.


If you have an environment that you identify with the tag `prod`, and each time you deployed an application to the prod environment you tagged the relevant application version in the Pact Broker with the tag `prod`, then calling `/can-i-deploy?pacticipant=Foo&version=734137278d&to=prod` will check that version 734137278d of Foo has a successful verification result with each of the integrated application versions that are currently in prod. That is, it is safe to deploy.
