# Can I Deploy

Allowed methods: `GET`

A simplified resource that accepts the same parameters as the basic usage of the `can-i-deploy` CLI command.

**Parameters**:

* _pacticipant_: The name of the pacticipant (application) you want to deploy (required).
* _version_: The version of the pacticipant (application) you want to deploy (required).
* _environment_: The name of the environment into which the pacticipant (application) is to be deployed. 
* _to_: The tag used to identify the environment into which you wish to deploy the application (eg. `test` or `prod`). Deprecated - use the `environment=ENVIRONMENT` parameter in preference to the `to=TAG` parameter as deployments and environments are now explictly supported.
* _ignore[]_: The name of the pacticipant to ignore when determining if it is safe to deploy (optional). May be used multiple times.


If you have an environment that you identify with the name `prod`, and each time you deployed an application to the prod environment you recorded the deployment of relevant application version in the Pact Broker using `record-deployment`, then calling `/can-i-deploy?pacticipant=Foo&version=734137278d&environment=prod` will check that version 734137278d of Foo has a successful verification result with each of the integrated application versions that are currently in prod. That is, it is safe to deploy.
