# num-ops-guide

Welcome to the NUM Operations Guide! This repository serves as a comprehensive guide for managing and automating operations within Kubernetes environments. Whether you're a developer, system administrator, or DevOps engineer, this guide aims to provide insights, best practices, and hands-on instructions to streamline operations and enhance your Kubernetes experience.

### Table of Contents

1. [How this Repo works](#)
   - [Argocd App-of-Apps pattern ](#argocd-app-of-apps-pattern)
   - [Prerequisites](#prerequisites)
   - [Repository Structure](#repository-structure)
   - [Deploy ArgoCD](#deploy-argocd)
   - [Adding a New Application](#adding-a-new-application)
   - [Example App](#examples-app)
   - [Adding a New Application](#argocd-app-of-apps-pattern)
   - [Example project-file](#example-project-file)
   - [Chart-folder structure](#chart-folder-structure)
   - [Links](#links)
1. [Principles](/docs/principles.md)
1. [Environments: development, staging, pre-prod, production](/docs/environments.md)
1. [Components](/docs/components.md)
1. [Getting Started](/docs/getting_started.md)
1. [DSF Develop](/docs/dsf_develop.md)
1. [Tips and Tricks](/docs/tips_and_tricks.md)
1. [Tasks & How-To's](/docs/tasks.md)
1. [Contributing](#contributing)
1. [License](#license)


### ArgoCD App-of-Apps Pattern

This repository uses the [ArgoCD App-of-Apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) to centrally manage multiple Kubernetes applications through a single root application.

### Prerequisites

- A running Kubernetes cluster  
- `kubectl` access to the cluster  
- Optional: `kustomize`, `helm`, `argocd` CLI

### Repository Structure

```bash
├── charts
│   ├── app-of-apps
│   │   ├── Chart.yaml
│   │   ├── templates
│   │   │   ├── app-argo-cd.yaml
│   │   │   ├── app-cert-manager.yaml
│   │   │   ├── app-cloudnative-pg.yaml
│   │   │   ├── app-homepage.yaml
│   │   │   ├── app-keycloak.yaml
│   │   │   ├── app-of-apps.yaml
│   │   │   ├── app-postgres-operator.yaml
│   │   │   ├── app-sealed-secrets-controller.yaml
│   │   │   ├── app-synthea-highmed.yaml
│   │   │   ├── app-victoria-logs.yaml
│   │   │   ├── application-dev-env.yaml
│   │   │   ├── develop-ehrshow
│   │   │   ├── dmu-development.yaml
│   │   │   ├── dmu-test.yaml
│   │   │   ├── greifswald-apps
│   │   │   ├── oci-bitnami-charts-secret.yaml
│   │   │   ├── project-dev-cluster.yaml
│   │   │   ├── project-dev-env.yaml
│   │   │   └── rdp-dev-fhirbridge
│   │   └── values.yaml

│   ├── app-of-apps-poc
│   ├── argo-cd
│   ├── argo-cd-poc
│   ├── cert-manager
│   ├── cloudnative-pg
│   ├── ehrbase
│   ├── fhir-bridge
│   ├── greifswald-apps
│   ├── hapi-fhir
│   ├── homepage
│   ├── keycloak
│   ├── open-fhir
│   ├── postgres-operator
│   ├── synthea-highmed
│   └── victoria-logs
├── docs
│   ├── assets
│   ├── components.md
│   ├── dsf_develop.md
│   ├── environments.md
│   ├── getting_started.md
│   ├── principles.md
│   ├── tasks.md
│   └── tips_and_tricks.md
├── hack
│   ├── allowlist
│   └── ehrbase-metrics
├── ingress-install.diff
├── keys
│   └── test
├── LICENSE
├── manifests
│   └── private-repo-example.yaml
├── README.md
├── terraform
│   └── stackit
└── test
    └── fhir-bridge
```

### Deploy ArgoCD

We'll use Helm to install Argo CD with the community-maintained chart from argoproj/argo-helm. The Argo project doesn't provide an official Helm chart.

Specifically, we are going to create a Helm "umbrella chart". This is basically a custom chart that wraps another chart. It pulls the original chart in as a dependency, and overrides the default values. In our case, we create an argo-cd Helm chart that wraps the community-maintained argo-cd Helm chart.

Using this approach, we have more flexibility in the future, by possibly including additional Kubernetes resources. The most common use case for this is to add Secrets (which could be encrypted using sops or SealedSecrets) to our application. For example, if we use webhooks with Argo CD, we have the possibility to securely store the webhook URL in a Secret.

    helm repo add argo-cd https://argoproj.github.io/argo-helm
    helm dep update charts/argo-cd/

We have to do the initial installation manually from our local machine, later we set up Argo CD to manage itself (meaning that Argo CD will automatically detect any changes to the helm chart and synchronize it.

    helm install --create-namespace --namespace argo argo-cd charts/argo-cd/

The Helm chart doesn't install an Ingress by default. To access the Web UI we have to port-forward to the argocd-server service on port 443:

    kubectl port-forward --namespace argo --address='00.0.0' svc/argo-cd-argocd-server 8080:443 &

We can then visit http://localhost:8080 to access it, which will show as a login form. The default username is `admin`. The password is auto-generated, we can get it with:

    kubectl get secret argocd-initial-admin-secret -n argo -o jsonpath="{.data.password}" | base64 -d


### Adding a New Application

1. Create a new directory under `charts/app-of-apps/templates`.
2. Create a corresponding `Application` manifest and a `Project` manifest.
3. In the `charts/` folder, create a new chart directory containing the Helm chart code you want to deploy.
4. If using an external repository, adjust the `path` and `repoURL` fields accordingly.
5. Once changes are pushed to the repository, the new Helm chart will be synced by ArgoCD automatically.

#### Example App

The following code creates a new application in ArgoCD and assigns it to the specified project, which can then be selected via the ArgoCD Web UI.

```helm
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: example-app
  namespace: {{ .Values.global.argoNamespace }}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: {{ .Values.projects.example.name }}
  source:
    repoURL: {{ .Values.projects.example.repoURL }}
    path: charts/example-app
    targetRevision: develop
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ .Values.projects.example.name }}
  syncPolicy:
    automated:
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```


#### Example project-file
This code creates the ArgoCD project where our new app will be placed. It is referenced in the Application manifest above.

```helm
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: {{ .Values.projects.example.name }}
  namespace: {{ .Values.global.argoNamespace }}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  description: {{ .Values.projects.example.description }}
  sourceRepos:
  - '*'
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
```

#### Chart-folder structure

```bash
├── Chart.yaml
├── templates
│   ├── Deployment.yaml
│   ├── Ingress.yaml
│   └── Service.yaml
└── values.yaml
```
---

### Links

- [ArgoCD App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [ArgoCD Helm Support](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)





