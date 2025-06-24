## Components

This guide covers the deployment and configuration of essential components for effective NUM operations:

* [Homepage](#homepage)
* [ArgoCD](#argocd)
* [Grafana](#grafana)
* [Prometheus](#prometheus)
* [VictoriaLogs](#victorialogs)
* [Sealed Secrets](#sealed-secrets)
  + [Creating a Sealed-Secret](#creating-a-sealed-secret)
  + [Extracting the main.key from the Cluster](#extracting-the-mainkey-from-the-cluster)
  + [Offline Decryption of a Sealed-Secret](#offline-decryption-of-a-sealed-secret)
* [MinIO (S3)](#minio-(s3))

##

### Homepage

- Url: https://homepage.dev.num-rdp.de
- Doku: https://gethomepage.dev
- Add your links here: https://github.com/NUM-Forschungsdatenplattform/num-ops-guide/blob/main/charts/homepage/values.yaml

### ArgoCD

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.
It enables automated application deployments, rollbacks, and easy management of multiple environments.
For our dev cluster use [argocd](https://argocd.dev.num-rdp.de).

### Grafana

Grafana is an open-source analytics and monitoring platform that integrates with various data sources, including Prometheus and Loki. It provides a customizable and feature-rich dashboard for visualizing metrics.

### Prometheus

Prometheus is an open-source monitoring and alerting toolkit designed for reliability and scalability. It scrapes and stores time-series data, making it a crucial component for monitoring Kubernetes clusters.

### VictoriaLogs

VictoriaLogs is [open source](https://github.com/VictoriaMetrics/VictoriaMetrics/tree/master/app/victoria-logs) user-friendly database for logs
from [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics/).

VictoriaLogs provides the following key features:

- VictoriaLogs can accept logs from popular log collectors. See [these docs](https://docs.victoriametrics.com/VictoriaLogs/data-ingestion/).
- VictoriaLogs is much easier to set up and operate compared to Elasticsearch and Grafana Loki.
  See [these docs](https://docs.victoriametrics.com/VictoriaLogs/QuickStart.html).
- VictoriaLogs provides easy yet powerful query language with full-text search capabilities across
  all the [log fields](https://docs.victoriametrics.com/VictoriaLogs/keyConcepts.html#data-model) -
  see [LogsQL docs](https://docs.victoriametrics.com/VictoriaLogs/LogsQL.html).
- VictoriaLogs can be seamlessly combined with good old Unix tools for log analysis such as `grep`, `less`, `sort`, `jq`, etc.
  See [these docs](https://docs.victoriametrics.com/VictoriaLogs/querying/#command-line) for details.
- VictoriaLogs capacity and performance scales linearly with the available resources (CPU, RAM, disk IO, disk space).
  It runs smoothly on both Raspberry PI and a server with hundreds of CPU cores and terabytes of RAM.
- VictoriaLogs can handle up to 30x bigger data volumes than Elasticsearch and Grafana Loki when running on the same hardware.
  See [these docs](#benchmarks).
- VictoriaLogs supports fast full-text search over high-cardinality [log fields](https://docs.victoriametrics.com/VictoriaLogs/keyConcepts.html#data-model)
  such as `trace_id`, `user_id` and `ip`.
- VictoriaLogs supports multitenancy - see [these docs](#multitenancy).
- VictoriaLogs supports out-of-order logs' ingestion aka backfilling.
- VictoriaLogs provides a simple web UI for querying logs - see [these docs](https://docs.victoriametrics.com/VictoriaLogs/querying/#web-ui).

VictoriaLogs is at the Preview stage now. It is ready for evaluation in production and verifying the claims given above.
It isn't recommended to migrate from existing logging solutions to VictoriaLogs Preview in general cases yet.
See the [Roadmap](https://docs.victoriametrics.com/VictoriaLogs/Roadmap.html) for details.

See also:

- [Using VictoriaLogs with Web UI](#using-victorialogs-with-web-ui)
- [Using VictoriaLogs from the command line](#using-victorialogs-from-the-command-line)

### Sealed Secrets

Sealed Secrets is a Kubernetes controller that allows securely storing Kubernetes Secrets in a Git repository or another version control system. The Secrets are encrypted using a public key and can only be decrypted with a private key that is available only within the Kubernetes cluster.

#### Creating a Sealed-Secret

To create a [Sealed-Secret](https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#sealed-secrets-for-kubernetes) follow these steps:

```bash
# Create a json/yaml-encoded Secret somehow:
# (note use of `--dry-run` - this is just a local file!)
kubectl create secret generic my-secret --from-literal=username=admin --from-literal=password=secretpassword --namespace=your-namespace --dry-run=client -o yaml > my-secret.yaml

# This is the important bit:
kubeseal -f mysecret.yaml -w mysealedsecret.yaml

# At this point mysealedsecret.yaml is safe to upload to Github

# Eventually:
kubectl create -f mysealedsecret.yaml

# Profit!
kubectl get secret mysecret
```

**Note:** The SealedSecret and Secret must have the same namespace and name. This is a feature to prevent other users on the same cluster from re-using your sealed secrets. See the Scopes section for more info.

kubeseal reads the namespace from the input secret, accepts an explicit --namespace argument, and uses the kubectl default namespace (in that order). Any labels, annotations, etc on the original Secret are preserved, but not automatically reflected in the SealedSecret.

#### Extracting the main.key from the Cluster

To extract the main.key from the Kubernetes cluster, execute the following command:

```bash
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > master-key.yaml
```

This saves the main.key value in master-key.yaml.

#### Offline Decryption of a Sealed-Secret

After extracting the main.key, a Sealed-Secret can now be decrypted offline using the kubeseal CLI tool. This can be done with the following command:

```bash
kubeseal --recovery-unseal --recovery-private-key master-key.yaml < sealed-secret.yaml
```

Note: It is important to securely store the main.key as it is needed to decrypt all sealed Secrets in the cluster.

### MinIO (S3)

MinIO is a high-performance, S3-compatible object storage solution designed for cloud-native applications. It supports scalability, strong consistency, and enterprise-grade features like erasure coding and encryption. Ideal for Kubernetes and containerized environments, MinIO is often used for backup, AI/ML, and big data workloads.

We use the [minio-operator](https://min.io/docs/minio/kubernetes/upstream/operations/install-deploy-manage/deploy-operator-helm.html) and [minio-tenant](https://min.io/docs/minio/kubernetes/openshift/operations/install-deploy-manage/deploy-minio-tenant-helm.html) helm-chart.

For the minio-tenant there is no build-in solution to create policies for buckets, so we created a [cronjob](https://raw.githubusercontent.com/NUM-Forschungsdatenplattform/num-ops-guide/refs/heads/main/charts/minio-tenant/templates/cronjob.yaml) and a [job](https://raw.githubusercontent.com/NUM-Forschungsdatenplattform/num-ops-guide/refs/heads/main/charts/minio-tenant/templates/job.yaml) which does this. The cronjob checks every 5 minutes if the policy is still active on the specific bucket.
