# num-ops-guide

Welcome to the NUM Operations Guide! This repository serves as a comprehensive guide for managing and automating operations within Kubernetes environments. Whether you're a developer, system administrator, or DevOps engineer, this guide aims to provide insights, best practices, and hands-on instructions to streamline operations and enhance your Kubernetes experience.

## Table of Contents

1. [Introduction](#introduction)
1. [Roadmap for this Guide](#todo)
    - [Research and Gather Information](#todo)
    - [Outline Guide Content Structure](#todo)
1. [Roadmap for the Cluster](#todo)
    - [ArgoCD](#todo)
    - [Vault](#vault)
    - [Observability](#vault)
    - [Central Research Repository](#central-research-repository)
1. [Principles](#principles)
1. [Concepts](#concepts)
    - [Environments: development, staging, pre-prod, production](#todo)
    - [Secrets management with HashiCorp Vault](#secrets-management-with-hashicorp-vault)
1. [Components](#components)
    - [ArgoCD](#argocd)
    - [Vault](#vault)
    - [Grafana](#grafana)
    - [Prometheus](#prometheus)
    - [Loki](#loki)
    - [Central Research Repository](#central-research-repository)
    - [...](#todo)
1. [Getting Started](#getting-started)
1. [Tasks](#tasks)
    - [Deploy ArgoCD](#deploy-argocd)
    - [Update ArgoCD](#update-argocd)
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

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It enables automated application deployments, rollbacks, and easy management of multiple environments.

### Grafana

Grafana is an open-source analytics and monitoring platform that integrates with various data sources, including Prometheus and Loki. It provides a customizable and feature-rich dashboard for visualizing metrics.

### Prometheus

Prometheus is an open-source monitoring and alerting toolkit designed for reliability and scalability. It scrapes and stores time-series data, making it a crucial component for monitoring Kubernetes clusters.

### Loki

Loki is a horizontally scalable, multi-tenant log aggregation system inspired by Prometheus. It helps to collect, store, and search logs efficiently in a Kubernetes environment.

## Getting Started

Before diving into Kubernetes operations, make sure you have the necessary prerequisites installed. Consult the [official Kubernetes documentation](https://kubernetes.io/docs/setup/) for guidance on setting up `kubectl` for managing the Kubernetes cluster.


## Tasks

Follow the step-by-step instructions in the guide to deploy and configure each component. The guide is continually updated to include the latest best practices and improvements.

### Deploy ArgoCD

We'll use Helm to install Argo CD with the community-maintained chart from argoproj/argo-helm. The Argo project doesn't provide an official Helm chart.

Specifically, we are going to create a Helm "umbrella chart". This is basically a custom chart that wraps another chart. It pulls the original chart in as a dependency, and overrides the default values. In our case, we create an argo-cd Helm chart that wraps the community-maintained argo-cd Helm chart.

Using this approach, we have more flexibility in the future, by possibly including additional Kubernetes resources. The most common use case for this is to add Secrets (which could be encrypted using sops or SealedSecrets) to our application. For example, if we use webhooks with Argo CD, we have the possibility to securely store the webhook URL in a Secret.

Before we install our chart, we need to generate a Helm chart lock file for it. When installing a Helm chart, Argo CD checks the lock file for any dependencies and downloads them. Not having the lock file will result in an error.

    $ helm repo add argo-cd https://argoproj.github.io/argo-helm
    $ helm dep update charts/argo-cd/

We have to do the initial installation manually from our local machine, later we set up Argo CD to manage itself (meaning that Argo CD will automatically detect any changes to the helm chart and synchronize it.

    $ helm install argo-cd charts/argo-cd/

The Helm chart doesn't install an Ingress by default. To access the Web UI we have to port-forward to the argocd-server service on port 443:

    $ kubectl port-forward svc/argo-cd-argocd-server 8080:443

We can then visit http://localhost:8080 to access it, which will show as a login form. The default username is `admin`. The password is auto-generated, we can get it with:

    $ kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

Or
    $ argocd admin initial-password

### Deploy the App of Apps

In general, when we want to add an application to Argo CD, we need to add an Application resource in our Kubernetes cluster. The resource needs to specify where to find manifests for our application.

The `root-app` is a Helm chart that renders Application manifests. Initially it has to be added manually, but after that we can just commit Application manifests with Git, and they will be deployed automatically.

Argo CD will not use helm install to install charts. It will render the chart with helm template and then apply the output with kubectl. This means we can't run helm list on a local machine to get all installed releases.

The first time we have to deploy the App of Apps manually, later we'll let Argo CD manage the root-app and synchronize it automatically:

$ helm template root-app/ | kubectl apply -f -



### TODO

TODO

## Contributing

Contributions are welcome! If you find issues, have suggestions, or want to contribute enhancements, please check our [contribution guidelines](CONTRIBUTING.md).

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).

Happy NUM operations!

