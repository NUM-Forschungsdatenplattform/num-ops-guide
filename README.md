# num-ops-guide

Welcome to the NUM Operations Guide! This repository serves as a comprehensive guide for managing and automating operations within Kubernetes environments. Whether you're a developer, system administrator, or DevOps engineer, this guide aims to provide insights, best practices, and hands-on instructions to streamline operations and enhance your Kubernetes experience.

## Table of Contents

1. [Introduction](#introduction)
1. [Roadmap for this Guide](#todo)
    - [Research and Gather Information](#todo)
    - [Outline Guide Content Structure](#todo)
1. [Roadmap for the Cluster](#todo)
    - [ArgoCD](#todo)
    - [Observability](#todo)
    - [Central Research Repository](#central-research-repository)
1. [Principles](#principles)
1. [Concepts](#concepts)
    - [Environments: development, staging, pre-prod, production](#todo)
    - [Secrets management with HashiCorp Vault](#secrets-management-with-hashicorp-vault)
1. [Components](#components)
    - [ArgoCD](#argocd)
    - [Grafana](#grafana)
    - [Prometheus](#prometheus)
    - [Loki](#loki)
    - [Central Research Repository](#central-research-repository)
    - [...](#todo)
1. [Getting Started](#getting-started)
1. [Tasks](#tasks)
    - [Deploy ArgoCD](#deploy-argocd)
    - [Add your private ssh key to get access to private num-helm-charts](#add-your-private-ssh-key-to-get-access-to-private-num-helm-charts)
    - [Deploy the App of Apps](#deploy-the-app-of-apps)
    - [Update ArgoCD](#update-argocd)
    - [Securing Kubernetes Services with Let's Encrypt, Nginx Ingress Controller, and Cert-Manag(securing-kubernetes-services-with-let's-encrypt,-nginx-ingress-controller,-and-cert-manager)
    - [Securing Kubernetes Services with Ingress-Nginx Controller and Basic Authentication](securing-kubernetes-services-with-ingress-nginx-controller-and-basic-authentication)
    - [Deploy a new version of the Central Research Repository to the production environment](#todo)
    - [...](#todo)
1. [Contributing](#contributing)
1. [License](#license)

## Introduction

Kubernetes is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. This guide focuses on the operational aspects of Kubernetes, providing a centralized resource for deploying, monitoring, and maintaining applications in a Kubernetes cluster.

## Principles

Efficiently managing a Kubernetes cluster involves adhering to fundamental principles that enhance stability, reliability, and ease of operation. The following principles serve as a guiding framework for successful cluster management:

### Keep it Simple

Simplicity is a key tenet in Kubernetes cluster management. Strive for straightforward configurations and avoid unnecessary complexity. This principle ensures easier troubleshooting, quicker onboarding for new team members, and overall maintainability.

### Embrace Best Practices

Leverage established best practices recommended by the Kubernetes community. Regularly review and apply updates to keep your cluster aligned with the latest advancements and security patches. Following best practices enhances the cluster's security, performance, and resilience.

### Use Declarative Configuration

Adopt a declarative approach to define the desired state of your applications and infrastructure. Utilize tools like Kubernetes manifests and Helm charts to express configurations declaratively. This simplifies cluster management, promotes version control, and facilitates automation.

### Implement GitOps Workflows

Integrate GitOps workflows to manage configuration changes. Store declarative configurations in a version-controlled Git repository and use tools like ArgoCD for automated deployment and synchronization. This ensures a consistent and auditable deployment process.

### Monitor Resource Utilization

Regularly monitor resource utilization within the cluster. Utilize tools like Prometheus and Grafana to gather metrics and create dashboards for tracking CPU, memory, and storage usage. Monitoring helps identify bottlenecks, optimize resource allocation, and maintain cluster health.

### Practice Regular Backups

Establish a robust backup strategy for critical cluster components and persistent data. Regularly backup etcd, configuration files, and important application data. Having reliable backups is crucial for disaster recovery and ensures minimal downtime in case of failures.

### Implement RBAC for Security

Enforce Role-Based Access Control (RBAC) to regulate access to cluster resources. Define granular permissions based on roles and responsibilities to enhance security. Regularly audit and review RBAC policies to ensure they align with organizational security requirements.

### Handling Secrets

Handling secrets, such as passwords or user names, securely is crucial in any DevOps environment. Here's a guide on how to manage secrets effectively:

#### Internal Services

For internal services, we generate passwords dynamically using tools like Helm charts, which allows you to template our Kubernetes manifests.
We use Sealed Secrets to encrypt sensitive data like passwords and store them as YAML files in your Git repository. Sealed Secrets leverages Kubernetes' native encryption mechanisms, ensuring that the secrets are encrypted both at rest and in transit.

#### External Secrets

For external secrets, especially those that are sensitive and cannot be stored in public repositories, it's important to use Kubernetes Secrets stored in a private repository with encryption at rest.

### Automate Operational Tasks

Automate repetitive operational tasks to reduce manual intervention and minimize the risk of human errors. Implement CI/CD pipelines for application deployments, use configuration management tools for cluster-wide configurations, and automate routine maintenance tasks.

### Plan for Scalability

Design the cluster with scalability in mind. Anticipate growth and plan for the scaling of both applications and infrastructure components. This ensures the cluster can handle increased workloads without sacrificing performance or stability.

### Continuously Learn and Evolve

Stay informed about Kubernetes updates, best practices, and evolving technologies in the ecosystem. Foster a culture of continuous learning and improvement within your team. Regularly revisit and update cluster management processes to align with industry advancements.

By adhering to these principles, we lay the foundation for a well-managed Kubernetes cluster that is scalable, secure, and resilient to changes.

## Components

This guide covers the deployment and configuration of essential components for effective NUM operations:

### ArgoCD

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.
It enables automated application deployments, rollbacks, and easy management of multiple environments.
For our dev cluster use [argocd](https://argocd.rdp-dev.ingress.k8s.highmed.org).

### Grafana

Grafana is an open-source analytics and monitoring platform that integrates with various data sources, including Prometheus and Loki. It provides a customizable and feature-rich dashboard for visualizing metrics.

### Prometheus

Prometheus is an open-source monitoring and alerting toolkit designed for reliability and scalability. It scrapes and stores time-series data, making it a crucial component for monitoring Kubernetes clusters.

### Loki

Loki is a horizontally scalable, multi-tenant log aggregation system inspired by Prometheus. It helps to collect, store, and search logs efficiently in a Kubernetes environment.

## Getting Started

Before diving into Kubernetes operations, make sure you have the necessary prerequisites installed. Consult the [official Kubernetes documentation](https://kubernetes.io/docs/setup/) for guidance on setting up `kubectl` for managing the Kubernetes cluster.

For local developement you can use [colima](https://github.com/abiosoft/colima).
To startup a k8s cluster, that matches the current prod env simply run:

    colima start --cpu 4 --memory 8 --arch x86_64 --kubernetes --kubernetes-version v1.24.6+k3s1

## Tasks

Follow the step-by-step instructions in the guide to deploy and configure each component. The guide is continually updated to include the latest best practices and improvements.

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

    kubectl port-forward --namespace argo --address='0.0.0.0' svc/argo-cd-argocd-server 8080:443 &

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

    helm template charts/app-of-apps/ | kubectl apply -f -

### Update ArgoCD

We previously installed Argo CD manually by running helm install from our local machine. This means that updates to Argo CD, like upgrading the chart version or changing the values.yaml, require us to execute the Helm CLI command from a local machine again. It's repetitive, error-prone and inconsistent with how we install other applications in our cluster.

The solution is to let Argo CD manage Argo CD. To be more specific: We let the Argo CD controller watch for changes to the argo-cd helm chart in our repo (under charts/argo-cd), render the Helm chart, and apply the resulting manifests. It's done using kubectl and asynchronous, so it is safe for Kubernetes to restart the Argo CD Pods after it has been executed.

The application manifest can be found here: [charts/app-of-apps/templates/argo-cd.yaml](charts/app-of-apps/templates/argo-cd.yaml)

Once the Argo CD application is green (synced) we're done. We can make changes to our Argo CD installation the same way we change other applications: by changing the files in the repo and pushing it to our Git repository.

In order to update Argo CD just increase the version in [charts/argo-cd/Chart.yaml](charts/argo-cd/Chart.yaml).

### Securing Kubernetes Services with Let's Encrypt, Nginx Ingress Controller, and Cert-Manager

#### Introduction

In today's landscape, securing our Kubernetes services is paramount. Let's Encrypt provides free SSL/TLS certificates, making HTTPS encryption accessible to everyone. Nginx Ingress Controller serves as a crucial component for routing traffic within our Kubernetes cluster. Cert-Manager automates the management and issuance of TLS certificates in Kubernetes. This section provides guidance on integrating Let's Encrypt, Nginx Ingress Controller, and Cert-Manager into our Kubernetes environment.

#### Configuring Let's Encrypt Issuer

Before we begin issuing certificates, we need to create an Issuer, which specifies the certificate authority from which signed x509 certificates can be obtained.
The Let’s Encrypt certificate authority offers both a staging server for testing your certificate configuration, and a production server for rolling out verifiable TLS certificates.

Let’s create a test ClusterIssuer to make sure the certificate provisioning mechanism is functioning correctly. A ClusterIssuer is not namespace-scoped and can be used by Certificate resources in any namespace.

```yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
        name: letsencrypt-staging
        namespace: cert-manager
    spec:
        acme:
            # Email address used for ACME registration
            email: admin@example.org
            # The ACME server URL
            server: https://acme-staging-v02.api.letsencrypt.org/directory
            # Name of a secret used to store the ACME account private key
            privateKeySecretRef:
            name: letsencrypt-staging-issuer-account-key
            # Add a single challenge solver, HTTP01 using nginx
            solvers:
            - http01:
                ingress:
                    ingressClassName: nginx
```

Here we specify that we’d like to create a ClusterIssuer called `letsencrypt-staging`, and use the Let’s Encrypt staging server. We’ll later use the production server to roll out our certificates, but the production server rate-limits requests made against it, so for testing purposes we should use the staging URL.

We then specify an email address to register the certificate, and create a Kubernetes Secret called `letsencrypt-staging-issuer-account-key` to store the ACME account’s private key. We also use the HTTP-01 challenge mechanism. To learn more about these parameters, consult the official cert-manager documentation on Issuers.

The ClusterIssuer for the production server is defined here: [letsencrypt-prod-cluster-issuer.yaml](charts/cert-manager/templates/letsencrypt-prod-cluster-issuer.yaml).

#### Cert-Manager and Ingress

To request TLS signed certificates we annotations to our Ingress resources and cert-manager will facilitate creating the Certificate resource for us. A small sub-component of cert-manager, ingress-shim, is responsible for this. Ingress-shim watches Ingress resources across our cluster. If it observes an Ingress with

    annotations:
        cert-manager.io/cluster-issuer: letsencrypt-staging

Ingress-shim  will ensure a Certificate resource with the name provided in the `tls.secretName` field and configured as described on the Ingress exists in the Ingress's namespace.

    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
    name: victoria-logs-ingress
    namespace: victoria-logs
    annotations:
        cert-manager.io/cluster-issuer: letsencrypt-staging
    spec:
        ingressClassName: nginx
        rules:
        - host: logs.example.org
            http:
            paths:
            - backend:
                service:
                    name: victoria-logs
                    port:
                    number: 9428
                path: /
                pathType: Prefix
        tls:
        - hosts:
            - logs.example.org
            secretName: victoria-logs-letsencrypt-staging-tls

When the Certificate resource has conditions like

    kubectl describe certificate victoria-logs-letsencrypt-prod-tls

    ...

    Conditions:
        Last Transition Time:  2024-03-02T13:29:51Z
        Message:               Certificate is up to date and has not expired
        Observed Generation:   1
        Reason:                Ready
        Status:                True
        Type:                  Ready

    ...

everything look fine and we can switch to the production issuer.

#### Conclusion

In conclusion, the integration of Let's Encrypt, Nginx Ingress Controller, and Cert-Manager offers a robust solution for securing Kubernetes services with SSL/TLS certificates. By following the steps outlined in this guide, we have established a reliable mechanism for automating the issuance and management of certificates within our Kubernetes environment.

The configuration of Let's Encrypt Issuer, whether in a staging or production environment, ensures that our certificates are obtained securely and efficiently. Through the use of ClusterIssuers and Ingress annotations, we have streamlined the process of requesting and managing TLS certificates for our services.

The ability to monitor the status of certificates using commands like `kubectl describe certificate` allows us to ensure that our certificates are up to date and valid, providing peace of mind regarding the security of our services.

As we transition from testing with the staging server to the production environment, we can confidently deploy our applications knowing that they are protected by industry-standard encryption protocols. This approach not only enhances the security posture of our Kubernetes cluster but also simplifies the management of SSL/TLS certificates, ultimately contributing to a more resilient and secure infrastructure.

#### Sources

- [Annotated Ingress resource](https://cert-manager.io/docs/usage/ingress/)
- [How to Set Up an Nginx Ingress with Cert-Manager on DigitalOcean Kubernetes](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes)


### Securing Kubernetes Services with Ingress-Nginx Controller and Basic Authentication

After setting up HTTPS for our Kubernetes Services it is file to use Basic Authentication to control access to them. I order to set up Basic Authentication we will do the following steps:

- Create htpasswd file
- Convert auth file into a sealed secret
- Create an ingress tied to the basic-auth secret
- Use curl to confirm authorization is required by the ingress
- Use curl with the correct credentials to connect to the ingress

#### Create htpasswd file

For the htpasswd file file, we nedd a username and a password. We generate them by using this helm template

    apiVersion: v1
    kind: Secret
    metadata:
        name: basic-auth-generated-secret
        annotations:
            argocd.argoproj.io/sync-options: "Delete=false"
    type: Opaque
    data:
        username: {{ printf "%s-%s" "u" (randAlphaNum 16) | b64enc | quote }}
        password: {{ printf "%s-%s" "p" (randAlphaNum 32) | b64enc | quote }}

When using argocd, each time, arrgocd syncs the status, new username and passwords are generated.
So we backup the generated username and password in an generic `basic-auth-input` Secret.

    export USERNAME=$(kubectl get secret basic-auth-generated-secret -o jsonpath="{.data.username}" | base64 -d)
    export PASSWORD=$(kubectl get secret basic-auth-generated-secret -o jsonpath="{.data.password}" | base64 -d)

    kubectl create secret generic basic-auth-input --from-literal=username="$USERNAME" --from-literal=password="$PASSWORD"

    echo user: "$USERNAME" password: "$PASSWORD"

To create the htpasswd file `auth`, we run

    htpasswd -bc auth "$USERNAME" "$PASSWORD"

#### Convert auth file into a sealed secret

We do not want to leak the username in this public repo, so we create a sealed secret to store the auth file:

    kubectl create secret generic basic-auth --from-file=auth -o yaml --dry-run=client | kubeseal -o yaml > basic-auth-sealed-secret.yaml

And update our repo:

    git add basic-auth-sealed-secret.yaml
    git commit -m "modified basic-auth-sealed-secret.yaml"
    git push

After syncing with argo-cd, the sealed-secrets-controller decrypts the sealed-secret into the `basic-auth` secret.

#### Create an ingress tied to the basic-auth secret

To use the basic auth file, we need to annotate the ingress like:

    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
    name: ingress-with-auth
    annotations:
        # type of authentication
        nginx.ingress.kubernetes.io/auth-type: basic
        # name of the secret that contains the user/password definitions
        nginx.ingress.kubernetes.io/auth-secret: basic-auth
        # message to display with an appropriate context why the authentication is required
        nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'

#### Use curl to confirm authorization is required by the ingress

    curl -Lv logs.rdp-dev.ingress.k8s.highmed.org

    *   Trying 134.76.15.219:80...
    * Connected to logs.rdp-dev.ingress.k8s.highmed.org (134.76.15.219) port 80
    > GET / HTTP/1.1
    > Host: logs.rdp-dev.ingress.k8s.highmed.org
    > User-Agent: curl/8.4.0
    > Accept: */*
    >
    < HTTP/1.1 308 Permanent Redirect
    < Date: Mon, 04 Mar 2024 09:53:50 GMT
    < Content-Type: text/html
    < Content-Length: 164
    < Connection: keep-alive
    < Location: https://logs.rdp-dev.ingress.k8s.highmed.org
    <
    * Ignoring the response-body
    * Connection #0 to host logs.rdp-dev.ingress.k8s.highmed.org left intact
    * Clear auth, redirects to port from 80 to 443
    * Issue another request to this URL: 'https://logs.rdp-dev.ingress.k8s.highmed.org/'
    *   Trying 134.76.15.219:443...
    * Connected to logs.rdp-dev.ingress.k8s.highmed.org (134.76.15.219) port 443
    * ALPN: curl offers h2,http/1.1
    * (304) (OUT), TLS handshake, Client hello (1):
    *  CAfile: /etc/ssl/cert.pem
    *  CApath: none
    * (304) (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (IN), TLS handshake, Server key exchange (12):
    * TLSv1.2 (IN), TLS handshake, Server finished (14):
    * TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
    * TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
    * TLSv1.2 (OUT), TLS handshake, Finished (20):
    * TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
    * TLSv1.2 (IN), TLS handshake, Finished (20):
    * SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
    * ALPN: server accepted h2
    * Server certificate:
    *  subject: CN=logs.rdp-dev.ingress.k8s.highmed.org
    *  start date: Mar  2 12:29:50 2024 GMT
    *  expire date: May 31 12:29:49 2024 GMT
    *  subjectAltName: host "logs.rdp-dev.ingress.k8s.highmed.org" matched cert's "logs.rdp-dev.ingress.k8s.highmed.org"
    *  issuer: C=US; O=Let's Encrypt; CN=R3
    *  SSL certificate verify ok.
    * using HTTP/2
    * [HTTP/2] [1] OPENED stream for https://logs.rdp-dev.ingress.k8s.highmed.org/
    * [HTTP/2] [1] [:method: GET]
    * [HTTP/2] [1] [:scheme: https]
    * [HTTP/2] [1] [:authority: logs.rdp-dev.ingress.k8s.highmed.org]
    * [HTTP/2] [1] [:path: /]
    * [HTTP/2] [1] [user-agent: curl/8.4.0]
    * [HTTP/2] [1] [accept: */*]
    > GET / HTTP/2
    > Host: logs.rdp-dev.ingress.k8s.highmed.org
    > User-Agent: curl/8.4.0
    > Accept: */*
    >
    < HTTP/2 401
    < date: Mon, 04 Mar 2024 09:53:51 GMT
    < content-type: text/html
    < content-length: 172
    < www-authenticate: Basic realm="Authentication Required"
    < strict-transport-security: max-age=15724800; includeSubDomains
    <
    <html>
    <head><title>401 Authorization Required</title></head>
    <body>
    <center><h1>401 Authorization Required</h1></center>
    <hr><center>nginx</center>
    </body>
    </html>
    * Connection #1 to host logs.rdp-dev.ingress.k8s.highmed.org left intact

#### Use curl with the correct credentials to connect to the ingress

    export USERNAME=$(kubectl get secret basic-auth-input -o jsonpath="{.data.username}" | base64 -d)
    export PASSWORD=$(kubectl get secret basic-auth-input -o jsonpath="{.data.password}" | base64 -d)

    curl -vu "$USERNAME:$PASSWORD" https://logs.rdp-dev.ingress.k8s.highmed.org

    *   Trying 134.76.15.219:443...
    * Connected to logs.rdp-dev.ingress.k8s.highmed.org (134.76.15.219) port 443
    * ALPN: curl offers h2,http/1.1
    * (304) (OUT), TLS handshake, Client hello (1):
    *  CAfile: /etc/ssl/cert.pem
    *  CApath: none
    * (304) (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (IN), TLS handshake, Server key exchange (12):
    * TLSv1.2 (IN), TLS handshake, Server finished (14):
    * TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
    * TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
    * TLSv1.2 (OUT), TLS handshake, Finished (20):
    * TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
    * TLSv1.2 (IN), TLS handshake, Finished (20):
    * SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
    * ALPN: server accepted h2
    * Server certificate:
    *  subject: CN=logs.rdp-dev.ingress.k8s.highmed.org
    *  start date: Mar  2 12:29:50 2024 GMT
    *  expire date: May 31 12:29:49 2024 GMT
    *  subjectAltName: host "logs.rdp-dev.ingress.k8s.highmed.org" matched cert's "logs.rdp-dev.ingress.k8s.highmed.org"
    *  issuer: C=US; O=Let's Encrypt; CN=R3
    *  SSL certificate verify ok.
    * using HTTP/2
    * Server auth using Basic with user 'u-****************'
    * [HTTP/2] [1] OPENED stream for https://logs.rdp-dev.ingress.k8s.highmed.org/
    * [HTTP/2] [1] [:method: GET]
    * [HTTP/2] [1] [:scheme: https]
    * [HTTP/2] [1] [:authority: logs.rdp-dev.ingress.k8s.highmed.org]
    * [HTTP/2] [1] [:path: /]
    * [HTTP/2] [1] [authorization: Basic dS0qKioqKioqKioqKioqKioqCg==]
    * [HTTP/2] [1] [user-agent: curl/8.4.0]
    * [HTTP/2] [1] [accept: */*]
    > GET / HTTP/2
    > Host: logs.rdp-dev.ingress.k8s.highmed.org
    > Authorization: Basic dS0qKioqKioqKioqKioqKioqCg==
    > User-Agent: curl/8.4.0
    > Accept: */*
    >
    < HTTP/2 200
    < date: Mon, 04 Mar 2024 10:01:53 GMT
    < content-type: text/html; charset=utf-8
    < content-length: 365
    < vary: Accept-Encoding
    < x-server-hostname: victoria-logs-victoria-logs-single-server-0
    < strict-transport-security: max-age=15724800; includeSubDomains
    <
    * Connection #0 to host logs.rdp-dev.ingress.k8s.highmed.org left intact
    <h2>Single-node VictoriaLogs</h2></br>See docs at <a href='https://docs.victoriametrics.com/VictoriaLogs/'>https://docs.victoriametrics.com/VictoriaLogs/</a></br>Useful endpoints:</br><a href="select/vmui">select/vmui</a> - Web UI for VictoriaLogs<br/><a href="metrics">metrics</a> - available service metrics<br/><a href="flags">flags</a> - command-line flags<br/>

#### Sources

- [Basic Authentication](https://kubernetes.github.io/ingress-nginx/examples/auth/basic/)


TODO

## Contributing

Contributions are welcome! If you find issues, have suggestions, or want to contribute enhancements, please check our [contribution guidelines](CONTRIBUTING.md).

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).

Happy NUM operations!

