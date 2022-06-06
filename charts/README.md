# pact-broker

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.100.0.1](https://img.shields.io/badge/AppVersion-2.100.0.1-informational?style=flat-square)

The Pact Broker is an application for sharing for Pact contracts and verification results

## Source Code

* <https://github.com/pact-foundation/pact_broker>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | common | 1.x.x |
| https://charts.bitnami.com/bitnami | postgresql | 11.x.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| broker | object | `{"annotations":{},"config":{"basicAuth":{"allowPublicRead":false,"enablePublicBadgeAccess":false,"publicHeartbeat":true,"readUser":{"existingSecret":"","existingSecretPasswordKey":"","existingSecretUsernameKey":"","password":"admin","username":"admin"},"writeUser":{"existingSecret":"","existingSecretPasswordKey":"","existingSecretUsernameKey":"","password":"admin","username":"admin"}},"disable_ssl":false},"containerPorts":{"http":9292,"https":8443},"containerSecurityContext":{"enabled":true,"runAsNonRoot":true,"runAsUser":1001},"labels":{},"livenessProbe":{"enabled":true,"failureThreshold":3,"initialDelaySeconds":300,"periodSeconds":1,"successThreshold":1,"timeoutSeconds":5},"podSecurityContext":{"enabled":true,"fsGroup":1001},"readinessProbe":{"enabled":true,"failureThreshold":3,"initialDelaySeconds":30,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1},"replicaCount":1,"resources":{"limits":{"cpu":"2500m","memory":"1024Mi"},"requests":{"cpu":"100m","memory":"512Mi"}}}` | Broker configuration  |
| broker.annotations | object | `{}` | Additional annotations that can be added to the Broker deployment |
| broker.config | object | `{"basicAuth":{"allowPublicRead":false,"enablePublicBadgeAccess":false,"publicHeartbeat":true,"readUser":{"existingSecret":"","existingSecretPasswordKey":"","existingSecretUsernameKey":"","password":"admin","username":"admin"},"writeUser":{"existingSecret":"","existingSecretPasswordKey":"","existingSecretUsernameKey":"","password":"admin","username":"admin"}},"disable_ssl":false}` | Pact Broker Config |
| broker.config.basicAuth | object | `{"allowPublicRead":false,"enablePublicBadgeAccess":false,"publicHeartbeat":true,"readUser":{"existingSecret":"","existingSecretPasswordKey":"","existingSecretUsernameKey":"","password":"admin","username":"admin"},"writeUser":{"existingSecret":"","existingSecretPasswordKey":"","existingSecretUsernameKey":"","password":"admin","username":"admin"}}` | Pact Broker Basic Authentication |
| broker.config.basicAuth.allowPublicRead | bool | `false` | Set to true if you want public read access, but still require credentials for writing.  |
| broker.config.basicAuth.enablePublicBadgeAccess | bool | `false` | Set this to true to allow status badges to be embedded in README files without requiring a hardcoded password. |
| broker.config.basicAuth.publicHeartbeat | bool | `true` | Set to true if you want the heartbeat endpoint to be publically accessible. This will have to be true if you have enabled basic auth.  |
| broker.config.basicAuth.readUser | object | `{"existingSecret":"","existingSecretPasswordKey":"","existingSecretUsernameKey":"","password":"admin","username":"admin"}` | Pact Broker Basic Authentication Credentials For Read user |
| broker.config.basicAuth.readUser.existingSecret | string | `""` | Name of an existing Kubernetes secret containing credentials to access the Pact Broker |
| broker.config.basicAuth.readUser.existingSecretPasswordKey | string | `""` | The key to which holds the value of the password within the existingSecret |
| broker.config.basicAuth.readUser.existingSecretUsernameKey | string | `""` | The key to which holds the value of the username within the existingSecret |
| broker.config.basicAuth.readUser.password | string | `"admin"` | Password for read access to the Pact Broker |
| broker.config.basicAuth.readUser.username | string | `"admin"` | Usermame for read access to the Pact Broker |
| broker.config.basicAuth.writeUser | object | `{"existingSecret":"","existingSecretPasswordKey":"","existingSecretUsernameKey":"","password":"admin","username":"admin"}` | Pact Broker Basic Authentication Credentials For Write user |
| broker.config.basicAuth.writeUser.existingSecret | string | `""` | Name of an existing Kubernetes secret containing credentials to access the Pact Broker |
| broker.config.basicAuth.writeUser.existingSecretPasswordKey | string | `""` | The key to which holds the value of the password within the existingSecret |
| broker.config.basicAuth.writeUser.existingSecretUsernameKey | string | `""` | The key to which holds the value of the username within the existingSecret |
| broker.config.basicAuth.writeUser.password | string | `"admin"` | Password for write access to the Pact Broker |
| broker.config.basicAuth.writeUser.username | string | `"admin"` | Usermame for write access to the Pact Broker |
| broker.config.disable_ssl | bool | `false` | If set to true, SSL verification will be disabled for the HTTP requests made by the webhooks |
| broker.containerPorts | object | `{"http":9292,"https":8443}` | Container port configuration  |
| broker.containerPorts.http | int | `9292` | http port  |
| broker.containerPorts.https | int | `8443` | http port  |
| broker.containerSecurityContext | object | `{"enabled":true,"runAsNonRoot":true,"runAsUser":1001}` | Pact Broker containers' [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container) |
| broker.containerSecurityContext.enabled | bool | `true` | Enable Pact Broker containers' Security Context |
| broker.containerSecurityContext.runAsNonRoot | bool | `true` | Set Pact Broker container's Security Context runAsNonRoot |
| broker.containerSecurityContext.runAsUser | int | `1001` | Set Pact Broker container's Security Context runAsUser |
| broker.labels | object | `{}` | Additional labels that can be added to the Broker deployment |
| broker.livenessProbe | object | `{"enabled":true,"failureThreshold":3,"initialDelaySeconds":300,"periodSeconds":1,"successThreshold":1,"timeoutSeconds":5}` | Pact Broker [Liveness Probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes)  |
| broker.livenessProbe.enabled | bool | `true` | Enable livenessProbe on Pact Broker containers |
| broker.livenessProbe.failureThreshold | int | `3` | Failure threshold for livenessProbe |
| broker.livenessProbe.initialDelaySeconds | int | `300` | Initial delay seconds for livenessProbe |
| broker.livenessProbe.periodSeconds | int | `1` | Period seconds for livenessProbe |
| broker.livenessProbe.successThreshold | int | `1` | Success threshold for livenessProbe |
| broker.livenessProbe.timeoutSeconds | int | `5` | Timeout seconds for livenessProbe |
| broker.podSecurityContext | object | `{"enabled":true,"fsGroup":1001}` | Pact Broker pods' [SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod) |
| broker.podSecurityContext.enabled | bool | `true` | Enable Pact Broker pods' Security Context |
| broker.podSecurityContext.fsGroup | int | `1001` | Set Pact Broker pod's Security Context fsGroup |
| broker.readinessProbe | object | `{"enabled":true,"failureThreshold":3,"initialDelaySeconds":30,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Pact Broker [Readiness Probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes)  |
| broker.readinessProbe.enabled | bool | `true` | Enable readinessProbe on Pact Broker containers |
| broker.readinessProbe.failureThreshold | int | `3` | Failure threshold for readinessProbe |
| broker.readinessProbe.initialDelaySeconds | int | `30` | Initial delay seconds for readinessProbe |
| broker.readinessProbe.periodSeconds | int | `10` | Period seconds for readinessProbe |
| broker.readinessProbe.successThreshold | int | `1` | Success threshold for readinessProbe |
| broker.readinessProbe.timeoutSeconds | int | `1` | Timeout seconds for readinessProbe |
| broker.replicaCount | int | `1` | Number of Pact Broker replicas to deploy |
| broker.resources | object | `{"limits":{"cpu":"2500m","memory":"1024Mi"},"requests":{"cpu":"100m","memory":"512Mi"}}` | Pact Broker [resource requests and limits](https://kubernetes.io/docs/user-guide/compute-resources/) |
| broker.resources.limits | object | `{"cpu":"2500m","memory":"1024Mi"}` | The resources limits for the Pact Broker containers |
| broker.resources.requests | object | `{"cpu":"100m","memory":"512Mi"}` | The requested resources for the Pact Broker containers |
| externalDatabase | object | `{"config":{"adapter":"","auth":{"existingSecret":"","existingSecretPasswordKey":"user-password","password":"","username":""},"databaseName":"","host":"","port":""},"enabled":false}` | External database configuration |
| externalDatabase.config.adapter | string | `""` | Database engine to use. Only allowed values are `postgres` or `sqlite`. More info [here](https://docs.pact.io/pact_broker/docker_images/pactfoundation#getting-started) |
| externalDatabase.config.auth | object | `{"existingSecret":"","existingSecretPasswordKey":"user-password","password":"","username":""}` | External database auth details that the Pact Broker will use to connect |
| externalDatabase.config.auth.existingSecret | string | `""` | Name of an existing Kubernetes secret containing the database credentials |
| externalDatabase.config.auth.existingSecretPasswordKey | string | `"user-password"` | The key to which the password will be stored under within existing secret. |
| externalDatabase.config.auth.password | string | `""` | Password for the non-root username for the Pact Broker |
| externalDatabase.config.auth.username | string | `""` | Non-root username for the Pact Broker |
| externalDatabase.config.databaseName | string | `""` | External database name |
| externalDatabase.config.host | string | `""` | Database host |
| externalDatabase.config.port | string | `""` | Database port number |
| externalDatabase.enabled | bool | `false` | Switch to enable or disable the externalDatabase connection |
| image | object | `{"pullPolicy":"IfNotPresent","pullSecrets":[],"registry":"docker.io","repository":"pactfoundation/pact-broker","tag":"2.100.0.1"}` | Pact Broker image information |
| image.pullPolicy | string | `"IfNotPresent"` | Specify a imagePullPolicy Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent' more info [here](https://kubernetes.io/docs/user-guide/images/#pre-pulling-images)  |
| image.pullSecrets | list | `[]` | Array of imagePullSecrets to allow pulling the Pact Broker image from private registries. PS: Secret's must exist in the namespace to which you deploy the Pact Broker. more info [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)   Example:   pullSecrets:    - mySecretName  |
| image.registry | string | `"docker.io"` | Pact Broker image registry |
| image.repository | string | `"pactfoundation/pact-broker"` | Pact Broker image repository |
| image.tag | string | `"2.100.0.1"` | Pact Broker image tag (immutable tags are recommended) |
| postgresql | object | `{"architecture":"standalone","auth":{"database":"bitnami_broker","existingSecret":"","password":"","secretKeys":{"adminPasswordKey":"admin-password","replicationPasswordKey":"replication-password","userPasswordKey":"user-password"},"username":"bn_broker"},"enabled":true}` | PostgreSQL [chart configuration](https://github.com/bitnami/charts/blob/master/bitnami/postgresql/values.yaml) |
| postgresql.architecture | string | `"standalone"` | PostgreSQL architecture (`standalone` or `replication`) |
| postgresql.auth | object | `{"database":"bitnami_broker","existingSecret":"","password":"","secretKeys":{"adminPasswordKey":"admin-password","replicationPasswordKey":"replication-password","userPasswordKey":"user-password"},"username":"bn_broker"}` | The authentication details of the Postgres database |
| postgresql.auth.database | string | `"bitnami_broker"` | Name for a custom database to create |
| postgresql.auth.existingSecret | string | `""` | Name of existing secret to use for PostgreSQL credentials |
| postgresql.auth.password | string | `""` | Password for the custom user to create |
| postgresql.auth.secretKeys | object | `{"adminPasswordKey":"admin-password","replicationPasswordKey":"replication-password","userPasswordKey":"user-password"}` | The secret keys Postgres will look for to retrieve the relevant password |
| postgresql.auth.secretKeys.adminPasswordKey | string | `"admin-password"` | The key in which Postgres well look for, for the admin password, in the existing Secret |
| postgresql.auth.secretKeys.replicationPasswordKey | string | `"replication-password"` | The key in which Postgres well look for, for the replication password, in the existing Secret |
| postgresql.auth.secretKeys.userPasswordKey | string | `"user-password"` | The key in which Postgres well look for, for the user password, in the existing Secret |
| postgresql.auth.username | string | `"bn_broker"` | Name for a custom user to create |
| postgresql.enabled | bool | `true` | Switch to enable or disable the PostgreSQL helm chart |
| service | object | `{"clusterIP":"","loadBalancerIP":"","nodePorts":{"http":"","https":""},"ports":{"http":80,"https":443},"type":"ClusterIP"}` | Service configuration |
| service.clusterIP | string | `""` | Pact Broker service clusterIP |
| service.loadBalancerIP | string | `""` | Pact Broker Service [loadBalancerIP](https://kubernetes.io/docs/user-guide/services/#type-loadbalancer) |
| service.nodePorts | object | `{"http":"","https":""}` | Service [NodePort configuration](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) |
| service.nodePorts.http | string | `""` | http nodePort |
| service.nodePorts.https | string | `""` | https nodePort |
| service.ports | object | `{"http":80,"https":443}` | Service port configuration |
| service.ports.http | int | `80` | Pact service HTTP port |
| service.ports.https | int | `443` | Pact service HTTPS port |
| service.type | string | `"ClusterIP"` | Kubernetes service type  |
| serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":true,"create":true,"labels":{},"name":"broker-sa"}` | Service Account Configuration |
| serviceAccount.annotations | object | `{}` | Additional custom annotations for the ServiceAccount. |
| serviceAccount.automountServiceAccountToken | bool | `true` | Auto-mount the service account token in the pod |
| serviceAccount.create | bool | `true` | Enable the creation of a ServiceAccount for Pact Broker pods |
| serviceAccount.labels | object | `{}` | Additional custom labels to the service ServiceAccount. |
| serviceAccount.name | string | `"broker-sa"` | Name of the created ServiceAccount If not set and `serviceAccount.create` is true, a name is generated |

## Configuration and Installation Details

### Configuring Chart PostgreSQL

With the Pact Broker Helm Chart, it bundles together the Pact Broker and a Bitnami PostgreSQL database - this can be enabled by switching `postgresql.enabled` to true (it is `true` by default). If switched on, the Helm Chart, on deployment, will automatically deploy a PostgreSQL instance and configure it with the credentials you specify. There are multiple ways of doing this that will be detailed below.

#### Automatic Database Credential Creation
This is the easiest of the configuration options. Here, the credentials for both the Admin and Database user will be automatically generated and put into a Kubernetes secret. This then will be automatically used by the Pact Broker. For this, ensure the following happens:
  - Keep `postgresql.auth.existingSecret` & `postgresql.auth.password` empty.

#### Specifying Password for PostgreSQL to Use
Here, you can specify the password that you want PostgreSQL to use for it's Database User (The user that the Pact Broker will use to connect to the database). For this, ensure the following happens:
  - Keep the `postgresql.auth.existingSecret` empty.
  - Set the `postgresql.auth.password` to the value that you want the User password to be.
  > **_NOTE:_** Be careful and mindful that the value you provide here is done in a secure way.

#### Specifying Existing Secret for PostgreSQL to Use
Here, you can specify an existing Kubernetes secret that you have created that contains the Password that you want PostgreSQL to use. The secret has to be in the same namespace as where you are deploying the Helm Chart. For this, ensure the following happens:
  - Create the Kubernetes secret with the Password inside.
  - Set `postgresql.auth.existingSecret` to the name of the Secret
  - PostgreSQL by default will look for the relevant Password keys that are set by default here `postgresql.auth.secretKeys`. So make sure that the Keys in the Secret match the default `secretKeys` values. More information [here](https://artifacthub.io/packages/helm/bitnami/postgresql)
  - For example, if you want PostgreSQL to use an existing Secret called `my-user-secret` that has the User password that you want to use inside it. Make sure that you create a Key inside that secret called `user-password` (this key can be found here `postgresql.auth.secretKeys.userPasswordKey`). i.e. `user-password=Password123`.

### Configuring External Database
If you want to use an external database with your Pact Broker, switch the `externalDatabase.enabled` flag to true and the `postgresql.enabled` to false.

The configuring of the `externalDatabase.config.host`, `externalDatabase.config.port`, `externalDatabase.config.adapter` and `externalDatabase.config.databaseName` should be pretty straight forward. The credential configuration however has two methods of configuration.

#### Specify Credentials via Values
Configure the Pact Broker by using the username credential that you configure via the `externalDatabase.config.auth.username` value and the password via the `externalDatabase.config.auth.password` value.
  > **_NOTE:_** Be careful and mindful that the values you provide here is done in a secure way.

#### Specify Credentials via Secret
Configure the Pact Broker to use an existing Secret to retrieve the user password as a means to connect to the database. Ensure that the Kubernetes Secret has the password in the `user-password` field and ensure that you have set `externalDatabase.config.auth.existingSecret` value to the name of the secret. To configure the username, you can use the `username` value.
