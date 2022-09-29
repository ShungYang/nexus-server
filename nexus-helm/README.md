## Introduction

從 Sonatype 官方的 [GitHub](https://sonatype.github.io/helm3-charts/) 下載 Helm Chart 再根據需求進行修改.


### When to Use This Helm Chart
Use this Helm chart if you are doing any of the following:
- Deploying either Nexus Repository Pro or OSS to an on-premises environment with bare metal/VM server (Node)
- Deploying a single Nexus Repository instance within a Kubernetes cluster that has a single Node configured

> **Note**: If you are using Nexus Repository Pro, your license file and embedded database will reside on the node and be mounted on the container as a Persistent Volume (required).


---

## Prerequisites for This Chart

- Kubernetes 1.19+
- PV provisioner support in the underlying infrastructure
- Helm 3
- Istio
- StorageClass

---

### 調整的內容

在看了 values.yaml 和 templates 的內容後可以發現官方使用 deployment 來 Nexus Repository 的佈署, 但由於透過 Storageclass 動態產生的 PV 在 Pod 重啟後無法再使用, 如果改用 PV 綁定 PVC 的話實務上又不好管理, 所以需要改使用 Statefulset 來佈署 Nexus Repository, 所以針對 Helm chart 需要做以下項目的調整.

- 將原本的 deployment 改為使用 statefulset 來佈署
- Service 由 Cluster IP 改為 Headless
- 不使用 Ingress 而是改為 Istio Gateway + Virtualservice
- 使用 statefulset → PVC → Storageclass (namespace 中需要先配置)

---

## Testing the Chart
To test the chart, use the following:
```bash
$ helm install --dry-run --debug --generate-name ./
```
To test the chart with your own values, use the following:
```bash
$ helm install --dry-run --debug --generate-name -f myvalues.yaml ./
```

---

## Installing the Chart

To install the chart, you can pass custom configuration values as follows:

```bash
$ helm install -f myvalues.yaml sonatype-nexus ./
```

The default login is randomized and can be found in `/nexus-data/admin.password` or you can get the initial static passwords (admin/admin123)
by setting the environment variable `NEXUS_SECURITY_RANDOMPASSWORD` to `false` in your `values.yaml`.

---
## Uninstalling the Chart

To uninstall/delete the deployment, use the following:

```bash
$ helm list
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
plinking-gopher         default         1               2021-03-10 15:44:57.301847 -0800 PST    deployed        nexus-repository-manager-29.2.0 3.29.2
$ helm delete plinking-gopher
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

---

## Configuration

### Persistence

需要先建立一個 StorageClass 讓 `PersistentVolumeClaim` of StatefulSet 來取用, 並自動生成 PV

### Values.yaml

The following table lists the configurable parameters of the Nexus chart and their default values.

| Parameter                                  | Description                                                                                  | Default                                                                                                                                         |
|--------------------------------------------|----------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| `deploymentStrategy`                       | Deployment Strategy                                                                          | `Recreate`                                                                                                                                      |
| `nexus.imagePullPolicy`                    | Nexus Repository image pull policy                                                                      | `IfNotPresent`                                                                                                                                  |
| `nexus.imagePullSecrets`                   | Secret to download Nexus Repository image from private registry                                         | `nil`                                                                                                                                           |
| `nexus.docker.enabled`                     | Enable/disable Docker support                                                                | `false`                                                                                                                                         |
| `nexus.docker.registries`                  | Support multiple Docker registries                                                           | (see below)                                                                                                                                     |
| `nexus.docker.registries[0].host`          | Host for the Docker registry                                                                 | `cluster.local`                                                                                                                                 |
| `nexus.docker.registries[0].port`          | Port for the Docker registry                                                                 | `5000`                                                                                                                                          |
| `nexus.docker.registries[0].secretName`    | TLS Secret Name for the ingress                                                              | `registrySecret`                                                                                                                                |
| `nexus.env`                                | Nexus Repository environment variables                                                                  | `[{INSTALL4J_ADD_VM_PARAMS: -Xms1200M -Xmx1200M -XX:MaxDirectMemorySize=2G -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap}]` |
| `nexus.resources`                          | Nexus Repository resource requests and limits                                                           | `{}`                                                                                                                                            |
| `nexus.nexusPort`                          | Internal port for Nexus Repository service                                                              | `8081`                                                                                                                                          |
| `nexus.securityContext`                    | Security Context (for enabling official image use `fsGroup: 2000`)                           | `{}`                                                                                                                                            |
| `nexus.labels`                             | Service labels                                                                               | `{}`                                                                                                                                            |
| `nexus.podAnnotations`                     | Pod Annotations                                                                              | `{}`                                                                                                                                            |
| `nexus.livenessProbe.initialDelaySeconds`  | LivenessProbe initial delay                                                                  | 30                                                                                                                                              |
| `nexus.livenessProbe.periodSeconds`        | Seconds between polls                                                                        | 30                                                                                                                                              |
| `nexus.livenessProbe.failureThreshold`     | Number of attempts before failure                                                            | 6                                                                                                                                               |
| `nexus.livenessProbe.timeoutSeconds`       | Time in seconds after liveness probe times out                                               | `nil`                                                                                                                                           |
| `nexus.livenessProbe.path`                 | Path for LivenessProbe                                                                       | /                                                                                                                                               |
| `nexus.readinessProbe.initialDelaySeconds` | ReadinessProbe initial delay                                                                 | 30                                                                                                                                              |
| `nexus.readinessProbe.periodSeconds`       | Seconds between polls                                                                        | 30                                                                                                                                              |
| `nexus.readinessProbe.failureThreshold`    | Number of attempts before failure                                                            | 6                                                                                                                                               |
| `nexus.readinessProbe.timeoutSeconds`      | Time in seconds after readiness probe times out                                              | `nil`                                                                                                                                           |
| `nexus.readinessProbe.path`                | Path for ReadinessProbe                                                                      | /                                                                                                                                               |
| `nexus.hostAliases`                        | Aliases for IPs in /etc/hosts                                                                | []                                                                                                                                              |
| `nexus.properties.override`                | Set to true to override default nexus.properties                                             | `false`                                                                                                                                         |
| `nexus.properties.data`                    | A map of custom nexus properties if `override` is set to true                                | `nexus.scripts.allowCreation: true`                                                                                                             |
| `ingress.enabled`                          | Create an ingress for Nexus Repository                                                                  | `true`                                                                                                                                          |
| `ingress.annotations`                      | Annotations to enhance ingress configuration                                                 | `{kubernetes.io/ingress.class: nginx}`                                                                                                          |
| `ingress.tls.secretName`                   | Name of the secret storing TLS cert, `false` to use the Ingress' default certificate         | `nexus-tls`                                                                                                                                     |
| `ingress.path`                             | Path for ingress rules. GCP users should set to `/*`.                                         | `/`                                                                                                                                             |
| `tolerations`                              | tolerations list                                                                             | `[]`                                                                                                                                            |
| `config.enabled`                           | Enable configmap                                                                             | `false`                                                                                                                                         |
| `config.mountPath`                         | Path to mount the config                                                                     | `/sonatype-nexus-conf`                                                                                                                          |
| `config.data`                              | Configmap data                                                                               | `nil`                                                                                                                                           |
| `deployment.annotations`                   | Annotations to enhance deployment configuration                                              | `{}`                                                                                                                                            |
| `deployment.initContainers`                | Init containers to run before main containers                                                | `nil`                                                                                                                                           |
| `deployment.postStart.command`             | Command to run after starting the container                                            | `nil`                                                                                                                                           |
| `deployment.terminationGracePeriodSeconds` | Update termination grace period (in seconds)                                                 | 120s                                                                                                                                            |
| `deployment.additionalContainers`          | Add additional Container                                                                     | `nil`                                                                                                                                           |
| `deployment.additionalVolumes`             | Add additional Volumes                                                                       | `nil`                                                                                                                                           |
| `deployment.additionalVolumeMounts`        | Add additional Volume mounts                                                                 | `nil`                                                                                                                                           |
| `secret.enabled`                           | Enable secret                                                                                | `false`                                                                                                                                         |
| `secret.mountPath`                         | Path to mount the secret                                                                     | `/etc/secret-volume`                                                                                                                            |
| `secret.readOnly`                          | Secret readonly state                                                                        | `true`                                                                                                                                          |
| `secret.data`                              | Secret data                                                                                  | `nil`                                                                                                                                           |
| `service.enabled`                          | Enable additional service                                                                    | `true`                                                                                                                                          |
| `service.name`                             | Service name                                                                                 | `nexus3`                                                                                                                                        |
| `service.labels`                           | Service labels                                                                               | `nil`                                                                                                                                           |
| `service.annotations`                      | Service annotations                                                                          | `nil`                                                                                                                                           |
| `service.type`                             | Service Type                                                                                 | `ClusterIP`                                                                                                                                     |
| `route.enabled`                            | Set to true to create route for additional service                                           | `false`                                                                                                                                         |
| `route.name`                               | Name of route                                                                                | `docker`                                                                                                                                        |
| `route.portName`                           | Target port name of service                                                                  | `docker`                                                                                                                                        |
| `route.labels`                             | Labels to be added to route                                                                  | `{}`                                                                                                                                            |
| `route.annotations`                        | Annotations to be added to route                                                             | `{}`                                                                                                                                            |
| `route.path`                               | Host name of Route e.g. jenkins.example.com                                                   | nil                                                                                                                                             |
| `serviceAccount.create`                    | Set to true to create ServiceAccount                                                         | `true`                                                                                                                                          |
| `serviceAccount.annotations`               | Set annotations for ServiceAccount                                                           | `{}`                                                                                                                                            |
| `serviceAccount.name`                      | The name of the service account to use. Auto-generate if not set and create is true.          | `{}`                                                                                                                                            |
| `persistence.enabled`                      | Set false to eliminate persistent storage                                                    | `true`                                                                                                                                          |
| `persistence.existingClaim`                | Specify the name of an existing persistent volume claim to use instead of creating a new one | nil                                                                                                                                             |
| `persistence.storageSize`                  | Size of the storage the chart will request                                                 | `8Gi`                                                                                                                                           |

