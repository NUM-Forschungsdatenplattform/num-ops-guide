# num-ops-guide

Welcome to the NUM Operations Guide! This repository serves as a comprehensive guide for managing and automating operations within Kubernetes environments. Whether you're a developer, system administrator, or DevOps engineer, this guide aims to provide insights, best practices, and hands-on instructions to streamline operations and enhance your Kubernetes experience.

1. [num-ops-guide](#num-ops-guide)
    + [Deploy ArgoCD](#deploy-argocd)
    + [Add your private ssh key to get access to private num-helm-charts](#add-your-private-ssh-key-to-get-access-to-private-num-helm-charts)
    + [Deploy the App of Apps](#deploy-the-app-of-apps)
    + [How to add an app to the app-op-apps](#how-to-add-an-app-to-the-app-op-apps)
      - [Create a helm chart for keycloak](#create-a-helm-chart-for-keycloak)
      - [Add keycloak to the app-op-apps](#add-keycloak-to-the-app-op-apps)
    + [Update ArgoCD](#update-argocd)
    + [Create admin Secret for Keycloak](#create-admin-secret-for-keycloak)
    + [Create admin Secret for ArgoCD](#create-admin-secret-for-argocd)
    + [Create user Secret for ArgoCD](#create-user-secret-for-argocd)
1. [Principles](/docs/principles.md)
1. [Environments: development, staging, pre-prod, production](/docs/environments.md)
1. [Components](/docs/components.md)
1. [Getting Started](/docs/getting_started.md)
1. [DSF Develop](/docs/dsf_develop.md)
1. [Tips and Tricks](/docs/tips_and_tricks.md)
1. [Tasks & How-To's](/docs/tasks.md)
1. [Contributing](#contributing)
1. [License](#license)

##

### Tree
```bash
num-ops-guide
├── charts
│   ├── app-of-apps
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

Before we install our chart, we need to generate a Helm chart lock file for it. When installing a Helm chart, Argo CD checks the lock file for any dependencies and downloads them. Not having the lock file will result in an error.

    helm repo add argo-cd https://argoproj.github.io/argo-helm
    helm dep update charts/argo-cd/

We have to do the initial installation manually from our local machine, later we set up Argo CD to manage itself (meaning that Argo CD will automatically detect any changes to the helm chart and synchronize it.

    helm install --create-namespace --namespace argo argo-cd charts/argo-cd/

The Helm chart doesn't install an Ingress by default. To access the Web UI we have to port-forward to the argocd-server service on port 443:

    kubectl port-forward --namespace argo --address='00.0.0' svc/argo-cd-argocd-server 8080:443 &

We can then visit http://localhost:8080 to access it, which will show as a login form. The default username is `admin`. The password is auto-generated, we can get it with:

    kubectl get secret argocd-initial-admin-secret -n argo -o jsonpath="{.data.password}" | base64 -d

Or

    argocd -n argo admin initial-password

### Add your private ssh key to get access to private num-helm-charts

    cp manifests/private-repo-example.yaml manifests/num-helm-charts-repo-secret.yaml

In `manifests/num-helm-charts-repo-secret.yaml` add your private ssh key.

    kubectl apply -f manifests/num-helm-charts-repo-secret.yaml

Check the `CONNECTION STATUS` of the `num-helm-charts-repo` in the ArgoCD UI (Settings -> Repositories)

Be sure, that `manifests/num-helm-charts-repo-secret.yaml` is still ignored by git.

### Deploy the App of Apps

In general, when we want to add an application to Argo CD, we need to add an Application resource in our Kubernetes cluster. The resource needs to specify where to find manifests for our application.

The `app-of-apps` is a Helm chart that renders Application manifests. Initially it has to be added manually, but after that we can just commit Application manifests with Git, and they will be deployed automatically.

Argo CD will not use helm install to install charts. It will render the chart with helm template and then apply the output with kubectl. This means we can't run helm list on a local machine to get all installed releases.

The first time we have to deploy the App of Apps manually, later we'll let Argo CD manage the app-of-apps and synchronize it automatically:

```sh
helm template charts/app-of-apps/ | kubectl apply -f -
```

### How to add an app to the app-op-apps

As an example, we add keycloak to the app-op-apps.

#### Create a helm chart for keycloak

- create a helm chart for keycloak in the `charts` folder

```yaml
apiVersion: v2
name: keycloak
version: 22.0.4
dependencies:
  - name: keycloakx
    alias: keycloak
    version: 2.3.0
    repository: https://codecentric.github.io/helm-charts
```

- use the `keycloak` version as chart version
- change the defaut values in a `values.yaml` file
- add other ressouces in a `templates` folder

#### Add keycloak to the app-op-apps

- in the `charts/app-of-apps/templates` folder copy an cluster app yaml e.g `app-cert-manager.yaml` to `app-keycloak.yaml`
- in `app-keycloak.yaml` change any `cert-manager` to `keycloak`
- add your changes to this repo and let ArgoCD do the work

### Update ArgoCD

We previously installed Argo CD manually by running helm install from our local machine. This means that updates to Argo CD, like upgrading the chart version or changing the values.yaml, require us to execute the Helm CLI command from a local machine again. It's repetitive, error-prone and inconsistent with how we install other applications in our cluster.

The solution is to let Argo CD manage Argo CD. To be more specific: We let the Argo CD controller watch for changes to the argo-cd helm chart in our repo (under charts/argo-cd), render the Helm chart, and apply the resulting manifests. It's done using kubectl and asynchronous, so it is safe for Kubernetes to restart the Argo CD Pods after it has been executed.

The application manifest can be found here: [charts/app-of-apps/templates/argo-cd.yaml](charts/app-of-apps/templates/argo-cd.yaml)

Once the Argo CD application is green (synced) we're done. We can make changes to our Argo CD installation the same way we change other applications: by changing the files in the repo and pushing it to our Git repository.

In order to update Argo CD just increase the version in [charts/argo-cd/Chart.yaml](charts/argo-cd/Chart.yaml).

### Create admin Secret for Keycloak

After `the app-of-apps` is deployed, we need to create admin secret for Keycloak.

```sh
export USERNAME=$(kubectl get secret generated-admin -n keycloak -o jsonpath="{.data.username}" | base64 -d)
export PASSWORD=$(kubectl get secret generated-admin -n keycloak -o jsonpath="{.data.password}" | base64 -d)

kubectl create secret generic admin -n keycloak --from-literal=username="$USERNAME" --from-literal=password="$PASSWORD"

echo Keycloak admin: "$USERNAME" password: "$PASSWORD"
```

### Create admin Secret for ArgoCD

After `the app-of-apps` is deployed, we need to create admin secret for ArgoCD.

```sh
export USERNAME=$(kubectl get secret generated-argocd-admin -n keycloak -o jsonpath="{.data.username}" | base64 -d)
export PASSWORD=$(kubectl get secret generated-argocd-admin -n keycloak -o jsonpath="{.data.password}" | base64 -d)

kubectl create secret generic argocd-admin -n keycloak --from-literal=username="$USERNAME" --from-literal=password="$PASSWORD"

echo ArgoCD admin: "$USERNAME" password: "$PASSWORD"
```

### Create user Secret for ArgoCD

After `the app-of-apps` is deployed, we need to create user secret for ArgoCD.

```sh
export USERNAME=$(kubectl get secret generated-argocd-user -n keycloak -o jsonpath="{.data.username}" | base64 -d)
export PASSWORD=$(kubectl get secret generated-argocd-user -n keycloak -o jsonpath="{.data.password}" | base64 -d)

kubectl create secret generic argocd-user -n keycloak --from-literal=username="$USERNAME" --from-literal=password="$PASSWORD"

echo ArgoCD user: "$USERNAME" password: "$PASSWORD"
```
